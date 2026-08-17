require "rails_helper"

# The Tailwind design system and the legacy Bootstrap stylesheet both live under
# app/assets and both answer to the logical name "application.css". Sprockets resolves
# by load-path order, and the two halves of the app are one bad resolution away from
# every Bootstrap page rendering unstyled. These pin the contract.
RSpec.describe "Asset resolution", type: :request do
  let(:assets) { Rails.application.assets }

  it "resolves application.css to the Bootstrap/AdminLTE manifest, not the Tailwind source" do
    asset = assets.find_asset("application.css")

    expect(asset).not_to be_nil
    expect(asset.filename.to_s).to end_with("app/assets/stylesheets/application.scss")
  end

  it "resolves tailwind.css to the compiled build, not the Tailwind source" do
    asset = assets.find_asset("tailwind.css")

    expect(asset).not_to be_nil
    expect(asset.filename.to_s).to end_with("app/assets/builds/tailwind.css")
  end

  it "compiles the design system tokens into the Tailwind build" do
    css = Rails.root.join("app/assets/builds/tailwind.css").read

    expect(css).to include("Figtree")
    expect(css).to include("/vendor/figtree/")
    expect(css).to include("/vendor/bootstrap-icons/")
  end

  it "self-hosts every font the design system references" do
    css = Rails.root.join("app/assets/builds/tailwind.css").read
    referenced = css.scan(%r{url\("?(/vendor/[^")]+)"?\)}).flatten.uniq

    expect(referenced).not_to be_empty
    missing = referenced.reject { |path| Rails.root.join("public", path.delete_prefix("/")).exist? }
    expect(missing).to be_empty, "font files referenced but not vendored: #{missing.inspect}"
  end
end
