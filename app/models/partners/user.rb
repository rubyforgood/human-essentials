# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  invited_by_type        :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :bigint
#  partner_id             :bigint
#
module Partners
  class User < Base
    self.table_name = "users"

    # If you change any of these options, adjust ConsolidatedLoginsController::DeviseMappingShunt accordingly
    devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
           :invitable, :trackable

    has_many :requests, class_name: 'Partners::Request', foreign_key: :partner_id, dependent: :destroy, inverse_of: :user
    has_many :submitted_partner_requests, class_name: 'Partners::Request', foreign_key: :partner_user_id, dependent: :destroy, inverse_of: :partner_user
    has_many :submitted_requests, class_name: 'Request', foreign_key: :partner_user_id, dependent: :destroy, inverse_of: :partner_user

    belongs_to :partner, dependent: :destroy

    validate :password_complexity

    def password_complexity
      return if password.blank? || password =~ /(?=.*?[#?!@$%^&*-])/

      errors.add :password, 'Complexity requirement not met. Please use at least 1 special character'
    end
  end
end
