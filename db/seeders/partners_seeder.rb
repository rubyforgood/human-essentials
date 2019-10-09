class PartnersSeeder
  PARTNERS = [
    { name: "Pawnee Parent Service", email: "someone@pawneeparent.org", status: :approved },
    { name: "Pawnee Homeless Shelter", email: "anyone@pawneehomelss.com", status: :invited },
    { name: "Pawnee Pregnancy Center", email: "contactus@pawneepregnancy.com", status: :invited },
    { name: "Pawnee Senior Citizens Center", email: "help@pscc.org", status: :recertification_required }
  ].freeze

  def self.seed(org)
    PARTNERS.each do |partner_options|
      Partner.find_or_create_by!(partner_options) do |location|
        location.organization = org
      end
    end
  end
end
