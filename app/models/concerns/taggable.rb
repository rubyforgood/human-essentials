module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings, source: :tag

    scope :by_tags, ->(tag_names) { left_joins(:tags).where(tags: {name: tag_names}) }

    accepts_nested_attributes_for :taggings, :tags

    def tags_for_display
      tags.map(&:name).sort.join(", ")
    end
  end
end
