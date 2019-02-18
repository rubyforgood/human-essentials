namespace :db do
  desc "Replace first Donation  with Adjustment"
  task replace_donation: :environment do
    Organization.order('id').each { |org| p "#{org.name} id: #{org.id}" }
    p 'Choose organization id:'
    input = STDIN.gets.strip
    organization = Organization.find_by(id: input)
    if organization.nil?
      p "There isn't organization with id=#{input}"
    else
      organization.donations.each do |donation|
        p "id: #{donation.id}, created: #{donation.created_at.strftime("%F")}, source: #{donation.source}, comment: #{donation.comment}"
      end
      p "Choose donation id:"
      input = STDIN.gets.strip
      donation = organization.donations.find_by(id: input)
      if donation.nil?
        p "There isn't donation with id=#{input}"
      else
        ActiveRecord::Base.transaction do
          adjustment = organization.adjustments.create!(storage_location_id: donation.storage_location_id, comment: "Starting Inventory")
          LineItem.where(itemizable_type: "Donation", itemizable_id: donation.id).find_each do |line_item|
            line_item.itemizable_type = "Adjustment"
            line_item.itemizable_id = adjustment.id
            line_item.save
          end
          donation.delete
          p "New adjustment has been created!"
        end
      end
    end
  end
end
