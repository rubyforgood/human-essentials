class SyncNDBNMembers
  def self.upload(member_file)
    begin
      member_entries = parse_csv(member_file)
    rescue ParseError => e
      return [e.message]
    end

    member_entries.flat_map do |row|
      member_id, account_name = row[:ndbn_member_number], row[:member_name]
      ndbn_member = NDBNMember.find_or_initialize_by(ndbn_member_id: member_id)
      ndbn_member.account_name = account_name
      ndbn_member.save

      begin
        Integer(member_id)
      rescue ArgumentError
        ndbn_member.errors.add(:ndbn_member_id, "id must be an integer")
      end

      ndbn_member.errors.full_messages.flat_map do |msg|
        "Issue with '#{member_id},#{account_name}'-> #{msg}"
      end
    end
  end

  def self.parse_csv(member_file)
    raise ParseError, "CSV upload is required." if member_file.nil?

    data = member_file.readlines
    data = data.drop(1) if /Update/.match?(data.first)
    CSV.parse(data.join, headers: true, header_converters: :symbol)
  rescue ArgumentError
    raise ParseError, "The CSV File provided was invalid."
  end
  private_class_method :parse_csv
end
