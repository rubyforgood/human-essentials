RSpec::Matchers.define :block_partner_access do |expected = {}|
  match do
    expect(response).to redirect_to(partners_dashboard_path)
    expect(flash[:error]).to eq("That screen is not available. Please switch to the correct role and try again.")
  end
end
