module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy, before_add: :set_organization_id
    has_many :tags, through: :taggings, source: :tag

    scope :by_tags, ->(tags) { left_joins(:tags).where(tags: {name: tags}) }

    accepts_nested_attributes_for :taggings, :tags

    private

    def set_organization_id(tagging)
      tagging.organization_id ||= organization_id
    end
  end
end
