# == Schema Information
#
# Table name: partner_groups
#
#  id                :bigint           not null, primary key
#  deadline_day      :integer
#  name              :string
#  reminder_schedule :string
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

  before_save do
    # To avoid constantly changing the start date of the reminder_schedule, only update the schedule if something has actually
    # changed.
    if should_update_reminder_schedule
      self.reminder_schedule = create_schedule
    end
  end

  validates :name, presence: true, uniqueness: { scope: :organization }
  validates :deadline_day, presence: true, if: :send_reminders?
end
