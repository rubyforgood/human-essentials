module Partners
  # SectionErrorService identifies which sections of the Partner Profile step-wise form
  # should expand when validation errors occur. This helps users easily locate and fix
  # fields with errors in specific sections.
  #
  # Usage:
  #   error_keys = [:website, :pick_up_name, :enable_quantity_based_requests]
  #   sections_with_errors = Partners::SectionErrorService.sections_with_errors(error_keys)
  #   # => ["media_information", "pick_up_person", "partner_settings"]
  #
  class SectionErrorService
    # Maps form sections to the associated fields (error keys) that belong to them.
    SECTION_FIELD_MAPPING = {
      media_information: %i[no_social_media_presence website twitter facebook instagram],
      partner_settings: %i[enable_child_based_requests enable_individual_requests enable_quantity_based_requests],
      pick_up_person: %i[pick_up_email pick_up_name pick_up_phone],
      area_served: %i[client_share county_id]
    }

    # Returns a list of unique sections that contain errors based on the given error keys.
    #
    # @param error_keys [Array<Symbol>] Array of attribute keys representing the fields with errors.
    # @return [Array<String>] An array of section names containing errors.
    def self.sections_with_errors(error_keys)
      error_keys.flat_map do |key|
        SECTION_FIELD_MAPPING.find { |_section, fields| fields.include?(key) }&.first
      end.compact.uniq.map(&:to_s)
    end
  end
end
