# frozen_string_literal: true

# A URL a user supplies and the app later renders as a link.
#
# **Two separate faults, both proven before this was written.**
#
# `URI::DEFAULT_PARSER.make_regexp` with no arguments accepts *any* scheme, so
# `javascript:alert(document.cookie)` was a valid `Organization#url` -- and `organizations/show`
# renders that field with `link_to`, which makes it a stored XSS: an organization admin sets it,
# and anyone who views the page and clicks runs script in their own session.
#
# `format:` is not anchored. Even with the scheme restricted, as `BroadcastAnnouncement#link`
# already had it, the regexp matches a *substring* -- so `"javascript:alert(1) http://decoy.com"`
# satisfied it, and that field is rendered as the "More info" link on every user's dashboard.
#
# Brakeman found the first of these (LinkToHref, weak confidence) once its version was bumped by a
# merge from main. The second was found by testing the fix.
module HttpUrlValidatable
  extend ActiveSupport::Concern

  # Anchored, and http(s) only. Everything else -- `javascript:`, `data:`, `file:` -- is rejected.
  HTTP_URL = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/

  class_methods do
    def validates_http_url(*attributes, message: "should look like 'https://www.example.com'")
      validates(*attributes, format: {with: HTTP_URL, message: message}, allow_blank: true)
    end
  end
end
