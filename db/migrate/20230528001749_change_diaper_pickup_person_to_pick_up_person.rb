class ChangeDiaperPickupPersonToPickUpPerson < ActiveRecord::Migration[7.0]
  def up
    Organization.find_each do |organization|
      if organization.partner_form_fields.include? 'diaper_pickup_person'
        index = organization.partner_form_fields.index('diaper_pickup_person')
        organization.partner_form_fields[index] = 'pick_up_person'
        organization.save
      end
    end
  end

  def down
    Organization.find_each do |organization|
      if organization.partner_form_fields.include? 'pick_up_person'
        index = organization.partner_form_fields.index('pick_up_person')
        organization.partner_form_fields[index] = 'diaper_pickup_person'
        organization.save
      end
    end
  end
end
