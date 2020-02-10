shared_examples_for "pagination", type: :feature do
  let(:model_f) { described_class.to_s.underscore.to_sym }
  let(:plural_model_name) { described_class.to_s.underscore.pluralize }
  let!(:url_prefix) { "/#{@organization.to_param}" }

  scenario "user can visit the paginated results for a given resource" do
    sign_in(@user)

    create_list(model_f, 200)

    visit url_prefix + "/" + plural_model_name

    within("tbody") do
      items = page.all("tr")
      expect(items.count).to eq 50
    end

    click_link('3')

    within(".pagination") do
      expect(page.find("li.active").text).to eq("3")
    end
  end
end
