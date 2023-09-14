# This service object is meant to archive a family and all of
# its children
module Partners
  module UpdateFamily
    extend ServiceObjectErrorsMixin
    # rubocop:disable Rails::SkipsModelValidations
    def self.archive(family)
      if family.children.exists?
        ActiveRecord::Base.transaction do
          family.update(archived: true, updated_at: Time.zone.now)
          family.children.update_all(archived: true, updated_at: Time.zone.now)
        rescue => e
          errors.add(:base, e.message)
          raise ActiveRecord::Rollback
        end
      end
      self
    end
    # rubocop:enable Rails::SkipsModelValidations
  end
end
