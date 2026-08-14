require "rails_helper"
require Rails.root.join("lib/quality/mutant_parser")

RSpec.describe Quality::MutantParser do
  subject(:parser) { described_class.new(path) }

  let(:path) { file.path }
  let(:file) { Tempfile.new("mutant_report") }

  after { file.close! }

  context "with a full mutant report" do
    before do
      file.write(<<~REPORT)
        Mutations: 120
        Kills: 108
        Alive: 12
        Timeouts: 0
        Results: 120
        Coverage: 90.00%
      REPORT
      file.flush
    end

    it "returns the mutation metrics" do
      expect(parser.parse).to eq({mutations: 120, kills: 108, kill_ratio: 90.0})
    end
  end

  context "with no mutations" do
    before do
      file.write(<<~REPORT)
        Mutations: 0
        Kills: 0
        Results: 0
        Coverage: 100.00%
      REPORT
      file.flush
    end

    it "returns zero mutations and trivial coverage" do
      expect(parser.parse).to eq({mutations: 0, kills: 0, kill_ratio: 100.0})
    end
  end

  context "when the coverage line is missing" do
    before do
      file.write("Mutations: 5\nKills: 4\n")
      file.flush
    end

    it "raises a ParseError" do
      expect { parser.parse }.to raise_error(Quality::MutantParser::ParseError, /Coverage/)
    end
  end

  context "when the file does not exist" do
    let(:path) { Rails.root.join("tmp/nonexistent_mutant.txt") }

    it "raises an error" do
      expect { parser.parse }.to raise_error(Errno::ENOENT)
    end
  end
end
