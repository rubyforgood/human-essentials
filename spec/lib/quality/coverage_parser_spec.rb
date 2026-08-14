require "rails_helper"
require Rails.root.join("lib/quality/coverage_parser")

RSpec.describe Quality::CoverageParser do
  subject(:parser) { described_class.new(path) }

  let(:path) { file.path }
  let(:file) { Tempfile.new("coverage_last_run") }

  after { file.close! }

  context "when the file contains line and branch results" do
    before do
      file.write({result: {line: 36.3, branch: 100.0}}.to_json)
      file.flush
    end

    it "returns line and branch coverage" do
      expect(parser.parse).to eq({line: 36.3, branch: 100.0})
    end
  end

  context "when branch coverage is missing" do
    before do
      file.write({result: {line: 12.5}}.to_json)
      file.flush
    end

    it "returns nil for branch" do
      expect(parser.parse).to eq({line: 12.5, branch: nil})
    end
  end

  context "when the file does not exist" do
    let(:path) { Rails.root.join("tmp/nonexistent_coverage.json") }

    it "raises an error" do
      expect { parser.parse }.to raise_error(Errno::ENOENT)
    end
  end
end
