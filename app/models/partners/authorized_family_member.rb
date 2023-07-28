# == Schema Information
#
# Table name: authorized_family_members
#
#  id            :bigint           not null, primary key
#  comments      :text
#  date_of_birth :date
#  first_name    :string
#  gender        :string
#  last_name     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  family_id     :bigint
#
module Partners
  class AuthorizedFamilyMember < Base
    has_paper_trail
    belongs_to :family
    has_many :child_item_requests, dependent: :nullify

    def display_name
      "#{first_name} #{last_name}"
    end
  end
end
