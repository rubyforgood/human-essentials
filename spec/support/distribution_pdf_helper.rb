module DistributionPDFHelper
  def compare_pdf(organization, distribution, expected_file_path)
    pdf = DistributionPdf.new(organization, distribution)
    begin
      pdf_file = pdf.compute_and_render

      # Run the following from Rails sandbox console (bin/rails/console --sandbox) to regenerate these comparison PDFs:
      # => load "lib/pdf_comparison_test_factory.rb"
      # => Rails::ConsoleMethods.send(:prepend, PDFComparisonTestFactory)
      # => create_comparison_pdfs
      expect(pdf_file).to eq(IO.binread(expected_file_path))
    rescue RSpec::Expectations::ExpectationNotMetError => e
      File.binwrite(Rails.root.join("tmp", "failed_match_distribution_" + distribution.delivery_method.to_s + "_" + Time.current.to_s + ".pdf"), pdf_file)
      raise e.class, "PDF does not match, written to tmp/", cause: nil
    end
  end
end
