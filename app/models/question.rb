# == Schema Information
#
# Table name: questions
#
#  id         :bigint           not null, primary key
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Question < ApplicationRecord
  has_paper_trail
  has_rich_text :answer
  validates :answer, presence: true
  validates :title, presence: true
  scope :search_title, ->(query) { where("title ilike ?", "%#{query}%").includes([:rich_text_answer]) }

  # TODO: remove this line once migration `20250104193318_remove_for_banks_and_for_partners_from_questions` has been run in production
  self.ignored_columns += ["for_banks", "for_partners"]

  filterrific(
    available_filters: [
      :search_title
    ]
  )
end
