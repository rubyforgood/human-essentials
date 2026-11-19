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

  # The design system is loaded on the same pages as Bootstrap and AdminLTE. A Tailwind utility
  # named like a Bootstrap class would silently restyle legacy markup: `mb-3` is 0.75rem in
  # Tailwind and 1rem in Bootstrap, and Tailwind's `collapse` (visibility: collapse) would hide
  # every open Bootstrap collapsible. Scanning today's views as-is would emit ~90 of these.
  it "defines no class that the legacy Bootstrap/AdminLTE stylesheet also defines" do
    legacy = css_class_names(assets["application.css"].to_s)
    ours = css_class_names(build.read)

    expect(ours & legacy).to be_empty,
      "the design system build defines classes Bootstrap/AdminLTE already use: #{(ours & legacy).sort.inspect}"
  end

  def css_class_names(css)
    css
      .gsub(%r{/\*.*?\*/}m, "")           # comments
      .gsub(/url\([^)]*\)/, "")           # font and image URLs (".woff2", ".com")
      .gsub(/"[^"]*"|'[^']*'/, "")        # strings
      .scan(/\.(-?[A-Za-z_](?:\\.|[A-Za-z0-9_-])*)/)
      .flatten
      .map { |name| name.delete("\\") }
      .to_set
  end

  it "self-hosts every font the build references" do
    referenced = build.read.scan(%r{url\("?(/vendor/[^")]+)"?\)}).flatten.uniq

    expect(referenced).not_to be_empty
    missing = referenced.reject { |path| Rails.public_path.join(path.delete_prefix("/")).exist? }
    expect(missing).to be_empty, "font files referenced but not vendored: #{missing.inspect}"
  end
end
