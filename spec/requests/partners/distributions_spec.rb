RSpec.describe "/partners/distributions", type: :request do
  let(:partner) { create(:partner) }
  let(:partner_user) { partner.primary_user }

  describe "GET #index" do
    subject { -> { get partners_distributions_path } }

    before do
      sign_in(partner_user)
    end

    it "should render without any issues" do
      subject.call
      expect(response).to render_template(:index)
    end

    it "should display the distribution's ID" do
      # A distribution has to exist for the table to render at all: with none, the page shows
      # an empty state rather than bare table chrome, so this used to assert a column header
      # on a page that had no data in it.
      distribution = create(:distribution, :with_items, partner: partner)

      subject.call

      page = Nokogiri::HTML(response.body)
      headers = page.css("table thead tr th").map { |th| th.text.strip }
      ids = page.css("table tbody tr td").map { |td| td.text.strip }

      expect(headers).to include("ID")
      expect(ids).to include(distribution.id.to_s)
    end
  end

  describe "GET #print" do
    before do
      sign_in(partner_user)
    end

    let(:distribution) { FactoryBot.create(:distribution, partner: partner) }
    it "returns http success" do
      get print_partners_distribution_path(distribution)
      expect(response).to be_successful
    end

    context "with non-UTF8 characters" do
      let(:non_utf8_partner) { create(:partner, name: "KOKA Keiki O Ka ‘Āina") }

      it "returns http success" do
        get print_partners_distribution_path(distribution)
        expect(response).to be_successful
      end
    end
  end
end
