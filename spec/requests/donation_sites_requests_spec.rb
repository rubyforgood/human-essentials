RSpec.describe "DonationSites", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:params) { {} }

  describe "while signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      let!(:active_donation_site) { create(:donation_site, organization: organization, name: "An Active Site") }
      let!(:inactive_donation_site) { create(:donation_site, organization: organization, active: false, name: "An Inactive Site") }

      subject do
        get donation_sites_path(**params)
        response
      end

      it { is_expected.to be_successful }

      it "should show active donation sites with deactivate buttons" do
        get donation_sites_path
        page = Nokogiri::HTML(response.body)
        expect(response.body).to include("An Active Site")
        expect(response.body).not_to include("An Inactive Site")
        button1 = page.css(".btn[href='/donation_sites/#{active_donation_site.id}/deactivate']")
        expect(button1.text.strip).to eq("Deactivate")
        expect(button1.attr('class')).not_to match(/disabled/)
      end

      context "with include donation sites checkbox selected" do
        let(:params) { { include_inactive_donation_sites: "1" } }

        it "should show active donation sites with deactivate buttons" do
          get donation_sites_path(params)
          page = Nokogiri::HTML(response.body)
          expect(response.body).to include("An Active Site")
          expect(response.body).to include("An Inactive Site")

          # Active donation site should have deactivate button
          button1 = page.css(".btn[href='/donation_sites/#{active_donation_site.id}/deactivate']")
          expect(button1.text.strip).to eq("Deactivate")
          expect(button1.attr('class')).not_to match(/disabled/)

          # Inactive donation site should have reactivate button
          button2 = page.css(".btn[href='/donation_sites/#{inactive_donation_site.id}/reactivate']")
          expect(button2.text.strip).to eq("Restore")
          expect(button2.attr('class')).not_to match(/disabled/)
        end
      end

      context "csv" do
        subject do
          get donation_sites_path(format: :csv)
          response
        end

        let(:expected_headers) { ["Name", "Address", "Contact Name", "Email", "Phone"] }

        it { is_expected.to be_successful }

        it "has the expected csv headers" do
          subject

          csv = CSV.parse(response.body)
          expect(csv[0]).to eq(expected_headers)
        end

        it "only includes active donation sites by default" do
          subject

          csv = CSV.parse(response.body)

          # 1 row of headers + 1 row for active site
          expect(csv.length).to eq(2)

          # Expect active site to be present by name
          expect(csv[1][0]).to eq("An Active Site")
        end

        context "with include inactive donation sites selected" do
          subject do
            get donation_sites_path(include_inactive_donation_sites: "1", format: :csv)
            response
          end

          it "includes active and inactive donation sites" do
            subject

            csv = CSV.parse(response.body)

            # 1 row of headers + 1 row for active site + 1 row for inactive site
            expect(csv.length).to eq(3)

            csv_rows = csv[1..]
            donation_site_names = csv_rows.map(&:first)

            expect(donation_site_names).to include("An Active Site")
            expect(donation_site_names).to include("An Inactive Site")
          end
        end
      end
    end

    describe 'PUT #deactivate' do
      it 'should be able to deactivate an item' do
        donation_site = create(:donation_site, organization: organization, active: true, name: "to be deactivated")
        params = { id: donation_site.id }

        expect { put deactivate_donation_site_path(params) }.to change { donation_site.reload.active }.from(true).to(false)
        expect(response).to redirect_to(donation_sites_path)
      end
    end

    describe 'PUT #reactivate' do
      it 'should be able to reactivate an item' do
        donation_site = create(:donation_site, organization:, active: false, name: "to be reactivated")
        params = { id: donation_site.id }

        expect { put reactivate_donation_site_path(params) }.to change { donation_site.reload.active }.from(false).to(true)
        expect(response).to redirect_to(donation_sites_path)
      end
    end
  end
end
