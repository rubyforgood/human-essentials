class ConvertPartnerProfileAgencyTypesToEnums < ActiveRecord::Migration[7.0]
  def up
    Partners::Profile::AGENCY_TYPES.each do |enum, desc|
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE partner_profiles
        SET agency_type = '#{enum}'
        WHERE agency_type = '#{desc}'
      SQL
    end
  end

  def down
    Partners::Profile::AGENCY_TYPES.each do |enum, desc|
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE partner_profiles
        SET agency_type = '#{desc}'
        WHERE agency_type = '#{enum}'
      SQL
    end
  end
end
