require "rails_helper"

# The design system's Tailwind source and the legacy Bootstrap manifest both live under
# app/assets, and both answer to the logical name "application.css" (tailwindcss-rails
# hardcodes its input path). Sprockets resolves by load-path order, so one bad resolution
# would leave every existing page unstyled. These pin the contract, and the shape of the build.
RSpec.describe "Design system build", type: :request do
  let(:assets) { Rails.application.assets }
  let(:build) { Rails.root.join("app/assets/builds/tailwind.css") }

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

  it "compiles the design system typeface into the build" do
    expect(build.read).to match(/font-family:\s*"?Figtree/)
  end

  it "does not include Tailwind's Preflight reset, which would restyle every Bootstrap page" do
    # Preflight's signature rule: border-box sizing plus a zeroed border on every element.
    expect(build.read).not_to match(/box-sizing:\s*border-box;\s*border:\s*0 solid/)
  end

  it "self-hosts every font the build references" do
    referenced = build.read.scan(%r{url\("?(/vendor/[^")]+)"?\)}).flatten.uniq

    expect(referenced).not_to be_empty
    missing = referenced.reject { |path| Rails.public_path.join(path.delete_prefix("/")).exist? }
    expect(missing).to be_empty, "font files referenced but not vendored: #{missing.inspect}"
  end
end
