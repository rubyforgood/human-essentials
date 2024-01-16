require "rails_helper"

RSpec.describe "Donations", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  describe "while signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject do
        get donations_path(default_params.merge(format: response_format))
        response
      end

      before do
        create(:donation)
      end
      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }

        it "should have the columns source and details" do
          expect(subject.body).to include("<th>Source</th>")
          expect(subject.body).to include("<th>Details</th>")
        end

        context "when given a product drive" do
          let(:product_drive) { create(:product_drive) }
          let(:donation) { create(:donation, source: "Product Drive", product_drive: product_drive) }

          it "should display Product Drive and the name of the drive" do
            donation
            expect(subject.body).to include("<td>#{donation.source}</td>")
            expect(subject.body).to include("<td>#{product_drive.name}</td>")
          end
        end

        context "when given a donation site" do
          let(:donation_site) { create(:donation_site) }
          let(:donation) { create(:donation, source: "Donation Site", donation_site: donation_site) }

          it "should display Donation Site and the name of the site" do
            donation
            expect(subject.body).to include("<td>#{donation.source}</td>")
            expect(subject.body).to include("<td>#{donation_site.name}</td>")
          end
        end

        context "when given a manufacturer" do
          let(:manufacturer) { create(:manufacturer) }
          let(:donation) { create(:donation, source: "Manufacturer", manufacturer: manufacturer) }

          it "should display Manufacturer and the manufacturer name" do
            donation
            expect(subject.body).to include("<td>#{donation.source}</td>")
            expect(subject.body).to include("<td>#{manufacturer.name}</td>")
          end
        end

        context "when given a misc donation" do
          let(:donation) { create(:donation, source: "Misc. Donation", comment: Faker::Lorem.paragraph) }

          it "should display Misc Donation and a truncated comment" do
            donation
            short_comment = donation.comment.truncate(25, separator: /\s/)
            expect(subject.body).to include("<td>#{donation.source}</td>")
            expect(subject.body).to include("<td>#{short_comment}</td>")
          end
        end
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end
  end
end
