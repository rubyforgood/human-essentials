# == Schema Information
#
# Table name: roles
#
#  id              :bigint           not null, primary key
#  name            :string
#  resource_type   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  old_resource_id :bigint
#  resource_id     :bigint
#
class Role < ApplicationRecord
  has_paper_trail
  has_and_belongs_to_many :users, join_table: :users_roles
  accepts_nested_attributes_for :users

  belongs_to :resource,
    polymorphic: true,
    optional: true

  validates :resource_type,
    inclusion: {in: Rolify.resource_types},
    allow_nil: true

  scopify

  # constants to ensure we don't use invalid roles
  ORG_USER = :org_user
  ORG_ADMIN = :org_admin
  SUPER_ADMIN = :super_admin
  PARTNER = :partner

  TITLES = {
    org_user: "Organization",
    org_admin: "Organization Admin",
    partner: "Partner",
    super_admin: "Super admin"
  }.freeze

  TITLE_TO_RESOURCE = {
    org_user: ::Organization,
    org_admin: ::Organization,
    partner: ::Partner
  }.freeze

  # @return [String]
  def title
    TITLES[name.to_sym]
  end

  # @return [Hash<Symbol, String>]
  def self.resources_for_select
    TITLES.without(:super_admin).invert
  end
end
