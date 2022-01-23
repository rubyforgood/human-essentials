# == Schema Information
#
# Table name: partner_groups
#
#  id                    :bigint           not null, primary key
#  deadline_day_of_month :integer
#  name                  :string
#  reminder_day_of_month :integer
#  send_reminders        :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  organization_id       :bigint
#
class PartnerGroup < ApplicationRecord
  belongs_to :organization
  has_many :partners, dependent: :nullify
  has_and_belongs_to_many :item_categories

  validates :organization, presence: true
  validates :name, presence: true, uniqueness: { scope: :organization }
  validates :deadline_day_of_month, numericality: { only_integer: true, less_than_or_equal_to: 28, greater_than_or_equal_to: 1, allow_nil: true }
  validates :reminder_day_of_month, numericality: { only_integer: true, less_than_or_equal_to: 14, greater_than_or_equal_to: 1, allow_nil: true }
  validates :deadline_day_of_month, presence: true, if: -> { send_reminders }
  validates :reminder_day_of_month, presence: true, if: -> { send_reminders }

  # TODO: rename these in the DB
  def reminder_day
    reminder_day_of_month
  end

  def reminder_day=(x)
    self.reminder_day_of_month = x
  end

  def deadline_day
    deadline_day_of_month
  end

  def deadline_day=(x)
    self.deadline_day_of_month = x
  end
end
