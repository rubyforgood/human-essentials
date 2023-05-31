# This service object is meant to archive a family and all of
# its children
module Partners
  class ArchiveFamilyChildren
    include ServiceObjectErrorsMixin

    # rubocop:disable Rails::SkipsModelValidations
    def initialize(family:)
      @family = family
    end

    def call
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

    private

    attr_reader :family
  end
end
