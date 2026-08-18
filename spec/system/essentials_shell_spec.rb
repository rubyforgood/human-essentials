require "rails_helper"

# Smoke tests for the Ruby for Good design system shell. These render the real layout
# through a real controller action, so a missing helper, a bad partial path or a nav
# route that no longer exists fails here rather than in a page migration.
RSpec.describe "Essentials app shell", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:organization_admin, organization: organization) }

  before { sign_in(user) }

  context "chrome" do
    before { get dashboard_path }

    it "renders successfully on the Tailwind layout" do
      expect(response).to be_successful
    end

    it "loads the Tailwind stylesheet and NOT the Bootstrap one" do
      expect(response.body).to match(%r{<link[^>]+href="/assets/tailwind[^"]*\.css})
      expect(response.body).not_to match(%r{<link[^>]+href="/assets/application[^"]*\.css})
    end

    it "loads no third-party stylesheet" do
      # The Bootstrap shell <link>s Font Awesome, select2, toastr and Google Fonts on every
      # page. The design system self-hosts everything it needs, so a Tailwind page should
      # pull no stylesheet from anywhere but this app.
      external_stylesheets = response.body.scan(/<link[^>]+rel="stylesheet"[^>]*>/)
        .select { |tag| tag.match?(%r{href="https?://}) }

      expect(external_stylesheets).to be_empty
    end

    it "references only self-hosted fonts and icons" do
      expect(response.body).not_to include("fontawesome-free")
      expect(response.body).not_to include("fonts.googleapis.com")
    end

    it "ships exactly one main landmark, with a skip link pointing at it" do
      expect(response.body.scan("<main").length).to eq(1)
      expect(response.body).to include('href="#main-content"')
      expect(response.body).to include('id="main-content"')
    end

    it "declares a page language" do
      expect(response.body).to include(%(<html lang="en">))
    end

    it "marks the current nav item with aria-current, not colour alone" do
      expect(response.body).to include('aria-current="page"')
    end

    it "names the navigation landmark" do
      expect(response.body).to include('aria-label="Main"')
    end
  end

  context "role gating" do
    it "hides organization settings from a non-admin" do
      get dashboard_path
      expect(response.body).not_to include("My organization")
    end

    it "shows organization settings to an org admin" do
      sign_out(user)
      sign_in(admin)
      get dashboard_path
      expect(response.body).to include("My organization")
    end

    it "hides the inventory audit link from a non-admin" do
      get dashboard_path
      expect(response.body).not_to include("Inventory audit")
    end
  end

  context "navigation model" do
    it "renders every nav group label" do
      get dashboard_path
      %w[Operations Inventory Network].each do |label|
        expect(response.body).to include(label)
      end
    end

    it "renders Reports as a single destination rather than a group" do
      get dashboard_path
      expect(response.body).to include(">Reports<")
      expect(response.body).not_to include("nav-group-reporting")
    end

    it "renders every group collapsed when the current page is outside them all" do
      # The dashboard is ungrouped, so no group should be expanded on it.
      get dashboard_path
      expect(response.body).not_to include('aria-expanded="true"')
    end

    it "gives each group a labelled, controllable disclosure" do
      get dashboard_path
      expect(response.body).to include('aria-controls="nav-group-operations"')
      expect(response.body).to include('id="nav-group-operations"')
    end
  end
end
