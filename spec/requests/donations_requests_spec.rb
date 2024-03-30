require "rails_helper"

RSpec.describe "Donations", type: :request do
  let(:default_params) do
    { organization_name: @organization.to_param }
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

    describe "GET #show" do
      let(:item) { create(:item) }
      let!(:donation) { create(:donation, :with_items, item: item) }

      it "shows an enabled edit button" do
        get donation_path(default_params.merge(id: donation.id))
        page = Nokogiri::HTML(response.body)
        edit = page.at_css("a[href='#{edit_donation_path(default_params.merge(id: donation.id))}']")
        expect(edit.attr("class")).not_to match(/disabled/)
        expect(response.body).not_to match(/please make the following items active:/)
      end

      context "with an inactive item" do
        before do
          item.update(active: false)
        end

        it "shows a disabled edit button" do
          get donation_path(default_params.merge(id: donation.id))
          page = Nokogiri::HTML(response.body)
          edit = page.at_css("a[href='#{edit_donation_path(default_params.merge(id: donation.id))}']")
          expect(edit.attr("class")).to match(/disabled/)
          expect(response.body).to match(/please make the following items active: #{item.name}/)
        end
      end
    end

    describe "GET #edit" do
      context "when an finalized audit has been performed on the donated items" do
        it "shows a warning" do
          item = create(:item, organization: @organization, name: "Brightbloom Seed")
          storage_location = create(:storage_location, :with_items, item: item, organization: @organization)
          donation = create(:donation, :with_items, item: item, organization: @organization, storage_location: storage_location)
          create(:audit, :with_items, item: item, storage_location: storage_location, status: "finalized")

          get edit_donation_path(@organization.to_param, donation)

          expect(response.body).to include("You’ve had an audit since this donation was started.")
          expect(response.body).to include("In the case that you are correcting a typo, rather than recording that the physical amounts being donated have changed,\n")
          expect(response.body).to include("you’ll need to make an adjustment to the inventory as well.")
        end
      end
    end

    context "when an non-finalized audit has been performed on the donated items" do
      it "does not shows a warning" do
        item = create(:item, organization: @organization, name: "Brightbloom Seed")
        storage_location = create(:storage_location, :with_items, item: item, organization: @organization)
        donation = create(:donation, :with_items, item: item, organization: @organization, storage_location: storage_location)
        create(:audit, :with_items, item: item, storage_location: storage_location, status: "confirmed")

        get edit_donation_path(@organization.to_param, donation)

        expect(response.body).to_not include("You’ve had an audit since this donation was started.")
        expect(response.body).to_not include("In the case that you are correcting a typo, rather than recording that the physical amounts being donated have changed,\n")
        expect(response.body).to_not include("you’ll need to make an adjustment to the inventory as well.")
      end
    end

    context "when no audit has been performed" do
      it "doesn't show a warning" do
        item = create(:item, organization: @organization, name: "Brightbloom Seed")
        storage_location = create(:storage_location, :with_items, item: item, organization: @organization)
        donation = create(:donation, :with_items, item: item, organization: @organization, storage_location: storage_location)

        get edit_donation_path(@organization.to_param, donation)

        expect(response.body).to_not include("You’ve had an audit since this donation was started.")
        expect(response.body).to_not include("In the case that you are correcting a typo, rather than recording that the physical amounts being donated have changed,\n")
        expect(response.body).to_not include("you’ll need to make an adjustment to the inventory as well.")
      end
    end
  end
end
