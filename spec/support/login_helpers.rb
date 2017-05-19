def setup_organization(org = nil)
	org ||= create(:organization)
	controller.stub(:current_organization) { org }
end