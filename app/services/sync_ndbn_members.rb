class SyncNDBNMembers
  include ServiceObjectErrorsMixin

  def initialize(member_file)
    @member_file = member_file
  end
  attr_reader :member_file

  def call
    member_entries = parse_csv

    return if errors.any?

    member_entries.each do |member_id, account_name|
      ndbn_member = NDBNMember.find_or_initialize_by(ndbn_member_id: member_id.to_i)
      ndbn_member.account_name = account_name

      unless ndbn_member.save
        ndbn_member.errors.full_messages.each do |msg|
          error = "Issue with #{member_id}: #{account_name} -> #{msg}"
          errors.add(:base, error)
        end
      end
    end
  end

  private

  def parse_csv
    return errors.add(:base, "CSV upload is required.") if member_file.nil?

    raw = CSV.parse(member_file)

    raw.select do |member_id, member_name|
      member_id.match(/^\d+$/) && member_name.present?
    end
  rescue CSV::MalformedCSVError
    errors.add(:base, "The CSV File provided was invalid.")
  end
end
