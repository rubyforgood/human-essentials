class SyncNDBNMembers
  def self.upload(member_file)
    begin
      member_entries = parse_csv(member_file)
    rescue ParseError => e
      return [e.message]
    end

    member_entries.flat_map do |member_id, account_name|
      ndbn_member = NDBNMember.find_or_initialize_by(ndbn_member_id: member_id)
      ndbn_member.account_name = account_name
      ndbn_member.save

      # "some string".to_i == 0
      ndbn_member.errors.add(:ndbn_member_id, "id must be an integer") if member_id.to_i.zero?

      ndbn_member.errors.full_messages.flat_map do |msg|
        "Issue with '#{member_id},#{account_name}'-> #{msg}"
      end
    end
  end

  def self.parse_csv(member_file)
    raise ParseError, "CSV upload is required." if member_file.nil?

    data = CSV.parse(member_file)
    # Remove the first row because csv starts with Updated: 1/10/2024,
    data = data.drop(1) if data.first&.first&.start_with?("Updated")
    # Remove the headers, we are not using them.
    data = data.drop(1) if data.first&.first&.match?(/NDBN/i)
  rescue CSV::MalformedCSVError
    raise ParseError, "The CSV File provided was invalid."
  end
  private_class_method :parse_csv
end
