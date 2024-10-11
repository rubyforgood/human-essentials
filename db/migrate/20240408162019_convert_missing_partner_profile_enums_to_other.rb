class ConvertMissingPartnerProfileEnumsToOther < ActiveRecord::Migration[7.0]
  def up
    profiles = Partners::Profile
      .where.not(agency_type: Partner::AGENCY_TYPES.values)
      .in_batches

    profiles.each_record do |profile|
      profile.other_agency_type = profile.agency_type
      profile.agency_type = Partner::AGENCY_TYPES['OTHER']
      profile.save
    end
  end

  def down
    # Irreversible data migration
  end
end
