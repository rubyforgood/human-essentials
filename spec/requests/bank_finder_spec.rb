RSpec.describe "/find-a-bank", type: :request do
  before do
    create_census_locations
    import_sample_bank_listings
  end

  it "is public, and asks where you are when nothing has been searched" do
    get bank_finder_path

    expect(response).to be_successful
    expect(response.body).to include("Find a bank near you", "City and state, or ZIP code")
    expect(response.body).not_to include("bank-finder-results")
  end

  it "lists the nearest banks, closest first, with what they give out and how far" do
    get bank_finder_path(near: "Dayton, OH")

    expect(response.body).to include("Banks near Dayton, OH")
    names = Nokogiri::HTML(response.body).css("#bank-finder-results ol li p.font-medium").map(&:text)
    expect(names.first(3)).to eq(["Pawnee Diaper Bank", "Sweetums Period Project", "Eagleton Baby Pantry"])
    expect(response.body).to include("Diapers and period supplies", "Less than 5 miles", "About 47 miles")
    expect(response.body).not_to include("There is no bank within")
  end

  it "links each website off the app, safely" do
    get bank_finder_path(near: "45402")

    link = Nokogiri::HTML(response.body).at_css("a[href='https://www.pawneediapers.example']")
    expect(link.text).to eq("pawneediapers.example")
    expect(link["rel"]).to include("noopener")
  end

  it "never renders an imported website as a script link" do
    BankListing.find_by!(name: "Pawnee Diaper Bank").update!(website: "javascript:alert(1)//x")
    get bank_finder_path(near: "Dayton, OH")

    hrefs = Nokogiri::HTML(response.body).css("a").map { |a| a["href"] }
    expect(hrefs).to all(match(%r{\A(?:https?://|/)}))
    expect(hrefs).not_to include(a_string_starting_with("javascript"))
  end

  it "says so when the closest bank is far away, and still lists it" do
    get bank_finder_path(near: "59801")

    expect(response.body).to include("There is no bank within 50 miles", "Big Sky Diaper Bank")
  end

  it "asks which one for a city in more than one state, with a link to each" do
    get bank_finder_path(near: "Springfield")

    expect(response.body).to include("Which Springfield?")
    expect(response.body).to include(%(href="#{bank_finder_path(near: "Springfield, IL")}"))
  end

  it "says it could not find a place it does not know" do
    get bank_finder_path(near: "Atlantis, OH")

    expect(response.body).to include("We couldn't find &ldquo;Atlantis, OH&rdquo;")
  end
end
