class DonationsSeeder
  attr_accessor :organization

  def self.seed(organization)
    new(organization).seed
  end

  def initialize(organization)
    @organization = organization
  end

  def seed
    20.times.each do
      donation = donate(source)

      rand(1..5).times.each { create_line_item(donation) }

      donation.reload
      donation.storage_location.increase_inventory(donation)
    end
  end

  private

  def source
    Donation::SOURCES.values.sample
  end

  def donate(source)
    case source
    when Donation::SOURCES[:diaper_drive]
      create_donation_with_drive_participant(source)
    when Donation::SOURCES[:donation_site]
      create_donation_with_site(source)
    when Donation::SOURCES[:manufacturer]
      create_donation_with_manufacter(source)
    else
      donation_create(source, {})
    end
  end

  def create_donation_with_drive_participant(source)
    donation_create(
      source, diaper_drive_participant: random_record_for_org(organization, DiaperDriveParticipant)
    )
  end

  def create_donation_with_site(source)
    donation_create(
      source, donation_site: random_record_for_org(organization, DonationSite)
    )
  end

  def create_donation_with_manufacter(source)
    donation_create(
      source, manufacturer: random_record_for_org(organization, Manufacturer)
    )
  end

  def donation_create(source, source_params)
    params = {
      source: source,
      storage_location: random_record_for_org(organization, StorageLocation),
      organization: organization,
      issued_at: Faker::Date.between(from: 4.days.ago, to: Time.zone.today)
    }.merge(source_params)

    Donation.create!(params)
  end

  def create_line_item(donation)
    LineItem.create!(
      quantity: rand(250..500),
      item: random_record_for_org(organization, Item),
      itemizable: donation
    )
  end
end
