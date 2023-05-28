class ChangeDiaperPickupPersonToPickUpPerson < ActiveRecord::Migration[7.0]
  def up
    Organization.find_each do |organization|
      if organization.partner_form_fields.include? 'diaper_pickup_person'
        organization.partner_form_fields.delete('diaper_pickup_person')
        organization.partner_form_fields << 'pick_up_person'
        organization.save
      end
    end
  end

  def down
    Organization.find_each do |organization|
      if organization.partner_form_fields.include? 'pick_up_person'
        organization.partner_form_fields.delete('pick_up_person')
        organization.partner_form_fields << 'diaper_pickup_person'
        organization.save
      end
    end
  end
end
