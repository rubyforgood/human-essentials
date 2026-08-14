require "rails_helper"
require Rails.root.join("lib/quality/brakeman_parser")

RSpec.describe Quality::BrakemanParser do
  subject(:parser) { described_class.new(path) }

  let(:path) { file.path }
  let(:file) { Tempfile.new("brakeman_report") }

  after { file.close! }

  context "with warnings" do
    before do
      report = {
        "warnings" => [
          {"warning_type" => "SQL Injection"},
          {"warning_type" => "Cross Site Scripting"},
          {"warning_type" => "Command Injection"}
        ]
      }
      file.write(JSON.generate(report))
      file.flush
    end

    it "returns the number of warnings" do
      expect(parser.parse).to eq({warnings: 3})
    end
  end

  context "with no warnings" do
    before do
      file.write({warnings: []}.to_json)
      file.flush
    end

    it "returns zero" do
      expect(parser.parse).to eq({warnings: 0})
    end
  end

  context "when the warnings key is missing" do
    before do
      file.write({scan_info: {app_path: "/tmp"}}.to_json)
      file.flush
    end

    it "returns zero" do
      expect(parser.parse).to eq({warnings: 0})
    end
  end

  context "when the file does not exist" do
    let(:path) { Rails.root.join("tmp/nonexistent_brakeman.json") }

    it "raises an error" do
      expect { parser.parse }.to raise_error(Errno::ENOENT)
    end
  end
end
