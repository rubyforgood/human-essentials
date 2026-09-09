RSpec.describe HttpUrlValidatable do
  # Two separate faults, both proven before the fix and pinned here.
  #
  #   * `URI::DEFAULT_PARSER.make_regexp` with no arguments accepts any scheme, so
  #     `javascript:alert(document.cookie)` was a valid Organization#url -- and that field is
  #     rendered with `link_to`, which makes it stored XSS.
  #   * `format:` is not anchored, so even with the scheme restricted (as BroadcastAnnouncement#link
  #     already had it) a valid URL appended to a `javascript:` one satisfied the pattern.
  dangerous = [
    "javascript:alert(1)",
    "javascript:alert(document.cookie)",
    "JavaScript:alert(1)",
    "data:text/html,<script>alert(1)</script>",
    "file:///etc/passwd",
    # The anchoring bypass: a real URL appended to a dangerous one.
    "javascript:alert(1) http://decoy.example.com",
    "javascript:alert(1)#http://decoy.example.com"
  ]

  acceptable = [
    "http://example.com",
    "https://example.com",
    "https://www.example.com/path?query=1",
    "HTTPS://EXAMPLE.COM"
  ]

  # Each of the three fields, with the record built so nothing *else* makes it invalid -- the
  # assertion is on this attribute's own errors, not on `valid?`.
  subjects = {
    "Organization#url" => -> { [build(:organization), :url] },
    "BroadcastAnnouncement#link" => -> { [build(:broadcast_announcement), :link] },
    "AccountRequest#organization_website" => -> { [build(:account_request), :organization_website] }
  }

  subjects.each do |label, builder|
    describe label do
      dangerous.each do |value|
        it "rejects #{value.inspect}" do
          record, attribute = instance_exec(&builder)
          record.public_send("#{attribute}=", value)
          record.valid?
          expect(record.errors.attribute_names).to include(attribute)
        end
      end

      acceptable.each do |value|
        it "accepts #{value.inspect}" do
          record, attribute = instance_exec(&builder)
          record.public_send("#{attribute}=", value)
          record.valid?
          expect(record.errors.attribute_names).not_to include(attribute)
        end
      end

      it "still allows blank" do
        record, attribute = instance_exec(&builder)
        record.public_send("#{attribute}=", "")
        record.valid?
        expect(record.errors.attribute_names).not_to include(attribute)
      end
    end
  end
end
