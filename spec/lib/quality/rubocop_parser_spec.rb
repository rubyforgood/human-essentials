require "rails_helper"
require Rails.root.join("lib/quality/rubocop_parser")

RSpec.describe Quality::RubocopParser do
  subject(:parser) { described_class.new(path) }

  let(:path) { file.path }
  let(:file) { Tempfile.new("rubocop_report") }

  after { file.close! }

  context "with offenses from Metrics cops" do
    before do
      offenses = [
        {"cop_name" => "Metrics/MethodLength", "message" => "Method has too many lines. [26/15]"},
        {"cop_name" => "Metrics/MethodLength", "message" => "Method has too many lines. [18/15]"},
        {"cop_name" => "Metrics/ClassLength", "message" => "Class has too many lines. [150/100]"},
        {"cop_name" => "Metrics/AbcSize", "message" => "Assignment Branch Condition size for foo is too high. [23.4/15]"},
        {"cop_name" => "Layout/LineLength", "message" => "Line is too long. [95/80]"}
      ]
      report = {files: [{"path" => "app/models/foo.rb", "offenses" => offenses}]}
      file.write(JSON.generate(report))
      file.flush
    end

    it "extracts the maximum value per Metrics cop" do
      result = parser.parse
      expect(result[:method_length_max]).to eq(26)
      expect(result[:class_length_max]).to eq(150)
      expect(result[:abc_size_max]).to eq(23.4)
    end

    it "ignores non-Metrics cops" do
      expect(parser.parse[:method_length_max]).to eq(26)
    end

    it "leaves cops without offenses as nil" do
      expect(parser.parse[:module_length_max]).to be_nil
      expect(parser.parse[:cyclomatic_complexity_max]).to be_nil
      expect(parser.parse[:perceived_complexity_max]).to be_nil
    end

    it "returns whole numbers as integers" do
      expect(parser.parse[:method_length_max]).to eq(26)
      expect(parser.parse[:method_length_max]).to be_a(Integer)
    end

    it "returns fractional values as floats" do
      expect(parser.parse[:abc_size_max]).to eq(23.4)
    end
  end

  context "with no offenses" do
    before do
      file.write({files: [{"path" => "app/models/foo.rb", "offenses" => []}]}.to_json)
      file.flush
    end

    it "returns nil for every cop" do
      expect(parser.parse.values).to all(be_nil)
    end
  end

  context "when the file does not exist" do
    let(:path) { Rails.root.join("tmp/nonexistent_rubocop.json") }

    it "raises an error" do
      expect { parser.parse }.to raise_error(Errno::ENOENT)
    end
  end
end
