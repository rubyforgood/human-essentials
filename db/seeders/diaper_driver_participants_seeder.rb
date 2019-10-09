class DiaperDriverParticipantsSeeder
  def self.seed(org)
    [
      { business_name: "A Good Place to Collect Diapers",
        contact_name: "fred",
        email: "good@place.is",
        organization: org
      },
      { business_name: "A Mediocre Place to Collect Diapers",
        contact_name: "wilma",
        email: "ok@place.is",
        organization: org
      },
    ].each { |participant| DiaperDriveParticipant.create! participant }
  end
end
