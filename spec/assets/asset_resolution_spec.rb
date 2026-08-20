require "rails_helper"

# The design system stylesheet is the only one the app serves. These pin the things that would
# break it silently: serving the uncompiled Tailwind source, letting the Bootstrap stylesheet back
# in, or referencing a font the repo does not actually vendor.
#
# The pipeline is Propshaft, so resolution goes through `assets.load_path` rather than Sprockets'
# `find_asset`.
RSpec.describe "Asset resolution", type: :request do
  let(:load_path) { Rails.application.assets.load_path }

  it "serves no Bootstrap or AdminLTE stylesheet" do
    expect(load_path.find("application.css")).to be_nil
    expect(Rails.root.join("app/assets/stylesheets")).not_to exist
  end

  # tailwindcss-rails compiles app/assets/tailwind/application.css, whose first line is
  # `@import "tailwindcss"` -- not a stylesheet a browser can use. That directory is excluded from
  # the load path in application.rb so "application.css" cannot resolve to it.
  it "resolves tailwind.css to the compiled build, not the Tailwind source" do
    asset = load_path.find("tailwind.css")

    expect(asset).not_to be_nil
    expect(asset.path.to_s).to end_with("app/assets/builds/tailwind.css")
  end

  it "keeps the Tailwind source off the load path entirely" do
    expect(load_path.paths.map(&:to_s)).not_to include(a_string_ending_with("app/assets/tailwind"))
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

  # Those fonts live in public/, not on the asset load path, so Propshaft's CSS compiler leaves
  # their URLs alone -- it only quotes them. If they ever move into app/assets the digested paths
  # would change and this is where that would show up.
  it "serves the stylesheet with its font URLs intact" do
    get Rails.application.assets.load_path.find("tailwind.css").digested_path.to_s.prepend("/assets/")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('url("/vendor/figtree/')
    expect(response.body).to include('url("/vendor/bootstrap-icons/')
  end
end
