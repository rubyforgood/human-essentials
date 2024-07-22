# == Schema Information
#
# Table name: partner_groups
#
#  id                :bigint           not null, primary key
#  deadline_day      :integer
#  name              :string
#  reminder_schedule :string           saved in iCal format, eg "RRULE:FREQ=MONTHLY;BYMONTHDAY=14"
#  send_reminders    :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  organization_id   :bigint
#
class PartnerGroup < ApplicationRecord
  has_paper_trail
  include Deadlinable

  belongs_to :organization
  has_many :partners, dependent: :nullify
  has_and_belongs_to_many :item_categories

  validates :organization, presence: true
  validates :name, presence: true, uniqueness: { scope: :organization }
  validates :deadline_day, :reminder_schedule, presence: true, if: :send_reminders?
end
