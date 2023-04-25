# == Schema Information
#
# Table name: users_roles
#
#  id             :bigint           not null, primary key
#  last_active_at :datetime
#  role_id        :bigint
#  user_id        :bigint
#
class UsersRole < ApplicationRecord
  scope :by_last_active, -> { where.not(last_active_at: nil).order(last_active_at: :desc) }

  belongs_to :user
  belongs_to :role

  accepts_nested_attributes_for :user

  class << self
    # @param user [User]
    # @return [Role,nil]
    def current_role_for(user)
      return if user.blank?

      user.current_role || default_role_for(user)
    end

    def activate!(role:, user:)
      # rubocop:disable Rails/SkipsModelValidations
      where(role: role, user: user).update_all last_active_at: Time.current
      # rubocop:enable Rails/SkipsModelValidations
    end

    private

    def default_role_for(user)
      return if user.roles.blank?

      ::Role::HIERARCHY.each do |role|
        found_role = user.roles.find { |r| r.name.to_sym == role }
        return found_role if found_role
      end

      nil
    end
  end

  def activate!
    # rubocop:disable Rails/SkipsModelValidations
    update_column :last_active_at, Time.current
    # rubocop:enable Rails/SkipsModelValidations
  end
end
