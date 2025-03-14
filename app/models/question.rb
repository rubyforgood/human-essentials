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

  filterrific(
    available_filters: [
      :search_title
    ]
  )
end
