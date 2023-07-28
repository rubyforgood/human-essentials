# == Schema Information
#
# Table name: questions
#
#  id           :bigint           not null, primary key
#  for_banks    :boolean          default(TRUE), not null
#  for_partners :boolean          default(TRUE), not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Question < ApplicationRecord
  has_paper_trail
  has_rich_text :answer
  validates :answer, presence: true
  validates :title, presence: true
  validates :for_banks, acceptance: {message: "and for partners can't both be unchecked"}, unless: :for_partners
  validates :for_partners, acceptance: {message: "and for banks can't both be unchecked"}, unless: :for_banks
  scope :for_banks, -> { where(for_banks: true) }
  scope :for_partners, -> { where(for_partners: true) }
  scope :search_title, ->(query) { where("title ilike ?", "%#{query}%").includes([:rich_text_answer]) }

  filterrific(
    available_filters: [
      :search_title
    ]
  )

  def punctuate(errors)
    remove_redundant_error(errors).map { |error| error + ". " }.join("")
  end

  def remove_redundant_error(errors)
    if errors.include?("For banks and for partners can't both be unchecked")
      errors.delete("For banks and for partners can't both be unchecked")
    end
    errors
  end
end
