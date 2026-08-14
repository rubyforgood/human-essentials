# frozen_string_literal: true

require "fileutils"
require "shellwords"
require "yaml"

require_relative "../quality"
require_relative "../quality/coverage_parser"
require_relative "../quality/flog_parser"
require_relative "../quality/rubocop_parser"
require_relative "../quality/mutant_parser"
require_relative "../quality/brakeman_parser"
require_relative "../quality/report"

QUALITY_DIR = Rails.root.join("tmp/quality")
THRESHOLDS_PATH = Rails.root.join("config/quality_thresholds.yml")

MUTANT_SUBJECTS = %w[app lib].freeze
FLOG_FILES = Rails.root.glob("app/**/*.rb") + Rails.root.glob("lib/quality/*.rb")
MUTANT_BOOTSTRAP = Rails.root.join("script/mutant_bootstrap.rb").to_s

def quality_dir
  FileUtils.mkdir_p(QUALITY_DIR)
  QUALITY_DIR
end

def load_thresholds
  YAML.load_file(THRESHOLDS_PATH)
end

def ratchet_if_unset!(key_path, value)
  thresholds = load_thresholds
  return unless thresholds.dig(*key_path).nil?

  node = thresholds
  key_path[0..-2].each { |k| node = node[k] }
  node[key_path.last] = value
  File.write(THRESHOLDS_PATH, thresholds.to_yaml)
  puts "[quality] Ratchet set: #{key_path.join(".")} = #{value}"
end

namespace :quality do
  desc "Run RSpec with coverage; emit JSON to tmp/quality/coverage.json"
  task coverage: :environment do
    out_path = quality_dir.join("coverage.json")
    sh "bundle exec rspec --format progress --exclude-pattern '{spec/system/**{,/*/**}/*_spec.rb,spec/requests/**{,/*/**}/*_spec.rb}' > /dev/null 2>&1 || true"

    last_run = Rails.root.join("coverage/.last_run.json")
    parsed = Quality::CoverageParser.new(last_run).parse
    File.write(out_path, JSON.pretty_generate(parsed))

    ratchet_if_unset!(%w[coverage line_min], parsed[:line].round(2))
    ratchet_if_unset!(%w[coverage branch_min], parsed[:branch].round(2))
  end

  desc "Run RuboCop metrics; emit JSON to tmp/quality/rubocop.json"
  task rubocop: :environment do
    out_path = quality_dir.join("rubocop.json")
    sh "bundle exec rubocop --format json > #{out_path.to_s.shellescape} 2>/dev/null || true"
  end

  desc "Run Flog; emit JSON to tmp/quality/flog.json"
  task flog: :environment do
    out_path = quality_dir.join("flog.json")
    parsed = Quality::FlogParser.new(FLOG_FILES.map(&:to_s)).parse
    parsed[:method_max] = parsed[:method_max].round(2)
    parsed[:class_max] = parsed[:class_max].round(2)
    File.write(out_path, JSON.pretty_generate(parsed))

    ratchet_if_unset!(%w[flog method_max], parsed[:method_max])
    ratchet_if_unset!(%w[flog class_max], parsed[:class_max])
  end

  desc "Run Brakeman; emit JSON to tmp/quality/brakeman.json; set warnings_max threshold on first run"
  task brakeman: :environment do
    raw_path = quality_dir.join("brakeman_raw.json")
    sh "bundle exec brakeman --format json --confidence-level 2 --no-pager " \
       "-o #{raw_path.to_s.shellescape} || true"

    parsed = Quality::BrakemanParser.new(raw_path).parse
    out_path = quality_dir.join("brakeman.json")
    File.write(out_path, JSON.pretty_generate(parsed))
    raw_path.delete if raw_path.exist?

    ratchet_if_unset!(%w[brakeman warnings_max], parsed[:warnings])
  end

  desc "Run Mutant; emit JSON to tmp/quality/mutation.json; ratchet threshold on first run"
  task mutation: :environment do
    txt_path = quality_dir.join("mutation.txt")

    cmd = [
      "bundle", "exec", "mutant", "run",
      "--integration", "rspec",
      "--require", MUTANT_BOOTSTRAP,
      "--since", "main",
      "--usage", "opensource",
      "--", *MUTANT_SUBJECTS
    ]
    sh "#{cmd.shelljoin} > #{txt_path.to_s.shellescape} 2>&1 || true"

    parsed = Quality::MutantParser.new(txt_path).parse
    File.write(quality_dir.join("mutation.json"), JSON.pretty_generate(parsed))

    next if parsed[:mutations].zero?

    ratchet_if_unset!(%w[mutation kill_ratio_min], parsed[:kill_ratio].round(2))
  end

  task :clean_mutation_artifact do
    path = QUALITY_DIR.join("mutation.json")
    path.delete if path.exist?
  end

  desc "Fast local quality gate (everything except mutation testing)."
  task local: %w[
    quality:clean_mutation_artifact
    quality:coverage
    quality:rubocop
    quality:flog
    quality:brakeman
    quality:report
  ]

  desc "Aggregate quality measurements and compare against thresholds"
  task report: :environment do
    measurements = {}
    {
      coverage: "coverage.json",
      flog: "flog.json",
      mutation: "mutation.json",
      brakeman: "brakeman.json"
    }.each do |key, filename|
      path = quality_dir.join(filename)
      next unless File.exist?(path)

      measurements[key] = JSON.parse(File.read(path)).transform_keys(&:to_sym)
    end

    rubocop_path = quality_dir.join("rubocop.json")
    if File.exist?(rubocop_path)
      offenses = JSON.parse(File.read(rubocop_path)).fetch("files")
        .sum { |f| f["offenses"].length }
      measurements[:rubocop] = {offenses: offenses}
    end

    report = Quality::Report.new(measurements: measurements, thresholds: load_thresholds)
    puts report
    exit(1) unless report.passed?
  end
end

desc "Run the full quality gate (local + mutation testing)"
task quality: %w[
  quality:clean_mutation_artifact
  quality:coverage
  quality:rubocop
  quality:flog
  quality:brakeman
  quality:mutation
  quality:report
]
