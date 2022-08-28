class SyncNDBNMembers
  include HTTParty

  NDBN_MEMBERS_PAGE = "https://ndbn.memberclicks.net/member-ids".freeze

  class << self
    def sync
      Rails.logger.info("Syncing NDBNMember started.")

      members_page = fetch_members_page
      member_entries = extract_member_entries(members_page)

      member_entries.each do |member|
        ndbn_member = NDBNMember.find_or_initialize_by(ndbn_member_id: member[:ndbn_member_id])
        ndbn_member.account_name = member[:account_name]

        # Skip if nothing has changed!
        if ndbn_member.persisted? && !ndbn_member.changed?
          next
        elsif ndbn_member.persisted? && ndbn_member.changed?
          Rails.logger.info("#{ndbn_member.id} changed their account name from #{ndbn_member.account_name_was} to #{ndbn_member.account_name}.")
        elsif ndbn_member.new_record?
          Rails.logger.info("New record found! #{ndbn_member.id} - #{ndbn_member.account_name} has been added!")
        end

        Rails.logger.info("Updating....")
        if ndbn_member.save
          Rails.logger.info("Done!")
        else
          error_msg = "Failed to update #{ndbn_member_id} due to #{e.errors.full_messages}"
          Rails.logger.info(error_msg)
          Bugsnag.notify(error_msg)
        end
      end

      Rails.logger.info("Syncing NDBNMember finished.")
    end

    private

    def fetch_members_page
      res = get(NDBN_MEMBERS_PAGE)

      if res.code != 200
        raise "SyncNDBNMembers.sync failed due to getting a status code of #{res.code}"
      end

      res.body
    end

    def extract_member_entries(html_body)
      doc = Nokogiri::HTML(html_body)
      entries = doc.css(".contentpaneopen p").map { |t| t.text }

      # Removes the column header that only has the labels
      entries[1..].map do |entry|
        split = entry.split(/\s/)

        member_id = split[0].squish
        account_name = split[1..].join(" ")

        {
          ndbn_member_id: member_id,
          account_name: account_name
        }
      end
    end
  end
end
