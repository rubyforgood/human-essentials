require "open3"

# Autoloading CustomDeviseMailer in a fresh process used to raise
# "uninitialized constant CustomDeviseMailer" (#5745): devise_invitable 2.0.13's
# :action_mailer load hook resolved Devise.mailer while the class was still loading
# (fixed in 2.0.14, scambra/devise_invitable#929).
# CI eager-loads, which hides it, so this boots a separate non-eager-loaded process.
RSpec.describe "CustomDeviseMailer cold load" do
  it "resolves Devise.mailer when autoloaded first in a fresh process" do
    env = {"RAILS_ENV" => "test", "CI" => nil}
    output, status = Open3.capture2e(env, "bin/rails", "runner", "puts Devise.mailer.name", chdir: Rails.root.to_s)

    expect(status).to be_success, output
    expect(output.lines.map(&:strip)).to include("CustomDeviseMailer")
  end
end
