# == Schema Information
#
# Table name: broadcast_announcements
#
#  id              :bigint           not null, primary key
#  expiry          :date
#  link            :text
#  message         :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#  user_id         :bigint           not null
#
class BroadcastAnnouncement < ApplicationRecord
  include HttpUrlValidatable

  has_paper_trail
  belongs_to :user
  belongs_to :organization, optional: true
  # Scheme was already restricted here; the pattern was not anchored, so a valid URL appended to
  # a `javascript:` one satisfied it. Rendered as "More info" on every user's dashboard.
  validates_http_url :link
  validates :message, presence: true

  def expired?
    return false if expiry.nil?
    expiry < Time.zone.today
  end

  def self.filter_announcements(parent_org)
    BroadcastAnnouncement.where(organization_id: parent_org)
      .where("expiry IS NULL or expiry >= ?", Time.zone.today)
      .order(created_at: :desc)
  end
end
