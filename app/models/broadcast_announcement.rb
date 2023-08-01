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
  has_paper_trail
  belongs_to :user
  belongs_to :organization, optional: true
  validates :link, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :message, presence: true

  def expired?
    return false if expiry.nil?
    expiry < Time.zone.today
  end

  def self.filter_announcements(parent_org)
    BroadcastAnnouncement.where(organization_id: parent_org)
      .where("expiry IS ? or expiry >= ?", nil, Time.zone.today)
      .order(created_at: :desc)
  end
end
