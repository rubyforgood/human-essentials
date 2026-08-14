require "rails_helper"
require Rails.root.join("lib/quality/flog_parser")

RSpec.describe Quality::FlogParser do
  subject(:parser) { described_class.new(paths) }

  let(:file) { Tempfile.new("flog_sample.rb") }
  let(:paths) { [file.path] }

  after { file.close! }

  context "with a simple class" do
    before do
      file.write(<<~RUBY)
        class Sample
          def simple
            1 + 1
          end

          def other
            "hello"
          end
        end
      RUBY
      file.flush
    end

    it "returns a method max score" do
      expect(parser.parse[:method_max]).to be_a(Float)
      expect(parser.parse[:method_max]).to be > 0
    end

    it "returns a class max score at least as large as the biggest method" do
      result = parser.parse
      expect(result[:class_max]).to be >= result[:method_max]
    end
  end

  context "with no Ruby files" do
    let(:paths) { [] }

    it "returns zero scores" do
      expect(parser.parse).to eq({method_max: 0.0, class_max: 0.0})
    end
  end
end
