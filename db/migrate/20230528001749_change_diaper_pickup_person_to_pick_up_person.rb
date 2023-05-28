class ChangeDiaperPickupPersonToPickUpPerson < ActiveRecord::Migration[7.0]
  def up
    [Organization, Partner].each do |model|
      model.find_each do |record|
        if record.partner_form_fields.include? 'diaper_pickup_person'
          record.partner_form_fields.delete('diaper_pickup_person')
          record.partner_form_fields << 'pick_up_person'
          record.save
        end
      end
    end
  end

  def down
    [Organization, Partner].each do |model|
      model.find_each do |record|
        if record.partner_form_fields.include? 'pick_up_person'
          record.partner_form_fields.delete('pick_up_person')
          record.partner_form_fields << 'diaper_pickup_person'
          record.save
        end
      end
    end
  end
end
