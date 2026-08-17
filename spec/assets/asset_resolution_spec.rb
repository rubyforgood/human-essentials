require "rails_helper"

# The design system stylesheet is now the only one the app serves. These pin the things that
# would break it silently: serving the uncompiled Tailwind source, letting the Bootstrap
# stylesheet back in, or referencing a font the repo does not actually vendor.
RSpec.describe "Asset resolution", type: :request do
  let(:assets) { Rails.application.assets }

  it "serves no Bootstrap or AdminLTE stylesheet" do
    expect(assets.find_asset("application.css")).to be_nil
    expect(Rails.root.join("app/assets/stylesheets")).not_to exist
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
    missing = referenced.reject { |path| Rails.public_path.join(path.delete_prefix("/")).exist? }
    expect(missing).to be_empty, "font files referenced but not vendored: #{missing.inspect}"
  end
end
