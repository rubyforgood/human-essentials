shared_examples_for "pagination", type: :feature do
    let(:model_f) { described_class.to_s.underscore.to_sym }
    let(:plural_model_name){ described_class.to_s.underscore.pluralize }
    let!(:url_prefix) { "/#{@organization.to_param}" }

    scenario "User visits page displays with 100 records in it" do

        Kaminari.configure do |config|
            config.default_per_page = 25
        end

        sign_in(@user)

        create_list(model_f, 100)

        visit url_prefix + "/" + plural_model_name

        list_body = page.find("tbody")
        items = list_body.all("tr")

        expect(items.count).to eq 25

        within(".pagination") do
            expect(page.find("li.active").text).to eq("1")
        end

        visit url_prefix + "/" + plural_model_name + "?page=" + "3"

        within(".pagination") do
            expect(page.find("li.active").text).to eq("3")
        end

    end
end
