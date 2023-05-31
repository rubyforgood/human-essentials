# This service object is meant to archive a family and all of
# its children
module Partners
  class ArchiveFamilyChildren
    include ServiceObjectErrorsMixin

    attr_reader :family

    def initialize(family:)
      @family = family
    end

    def call
      if family.children.exists?
        ActiveRecord::Base.transaction do
          family.update(archived: true, updated_at: Time.zone.now)
          # rubocop:disable Rails::SkipsModelValidations
          family.children.update_all(archived: true, updated_at: Time.zone.now)
          # rubocop:enable Rails::SkipsModelValidations
        rescue => e
          errors.add(:base, e.message)
          raise ActiveRecord::Rollback
        end
      end
      self
    end
  end
end
