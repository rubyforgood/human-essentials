class SyncNDBNMembers
  include HTTParty
  include Scraping

  NDBN_MEMBERS_PAGE = 'https://ndbn.memberclicks.net/member-ids'.freeze
  elements :ndbn_member_entries, '.contentpaneopen p'

  class << self
    def sync
      members_page = fetch_members_page
      member_entries = extract_member_entries(members_page)

      member_entries.each do |member|
        ndbn = NDBNMember.find_or_initialize_by(ndbn_member_id: member[:ndbn_member_id])
        ndbn.account_name = member[:account_name]
        ndbn.save!
      end
    end

    private

    def fetch_members_page
      get(NDBN_MEMBERS_PAGE).body
    end

    def extract_member_entries(html_body)
      entries = scrape(html_body).ndbn_member_entries

      # Removes the column header that only has the labels
      entries.drop(1)

      entries[1..-1].map do |entry|
        split = entry.split(/\s/)

        member_id = split[0].squish
        account_name = split[1..-1].join(' ')

        {
          ndbn_member_id: member_id,
          account_name: account_name,
        }
      end
    end

  end
end
