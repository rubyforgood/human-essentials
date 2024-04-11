class SyncNDBNMembers
  def self.upload(member_file)
    begin
      member_entries = parse_csv(member_file)
    rescue ParseError => e
      return [e.message]
    end

    member_entries.flat_map do |member_id, account_name|
      ndbn_member = NDBNMember.find_or_initialize_by(ndbn_member_id: member_id.to_i)
      ndbn_member.account_name = account_name
      ndbn_member.save

      ndbn_member.errors.full_messages.flat_map do |msg|
        "Issue with #{member_id}: #{account_name} -> #{msg}"
      end
    end
  end

  def self.parse_csv(member_file)
    raise ParseError, "CSV upload is required." if member_file.nil?

    raw = CSV.parse(member_file)

    raw.select do |member_id, member_name|
      member_id.match(/^\d+$/) && member_name.present?
    end
  rescue CSV::MalformedCSVError
    raise ParseError, "The CSV File provided was invalid."
  end
  private_class_method :parse_csv
end
