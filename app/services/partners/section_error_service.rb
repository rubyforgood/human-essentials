module Partners
  # SectionErrorService identifies which sections of the Partner Profile step-wise form
  # should expand when validation errors occur. This helps users easily locate and fix
  # fields with errors in specific sections.
  #
  # Why this service is needed:
  # In the Partner Profile step-wise form, fields are grouped within collapsible sections.
  # When validation errors happen, this service maps the fields with errors to their sections,
  # ensuring the relevant sections open automatically so users can address the issues directly.
  #
  # Usage:
  #   error_keys = [:website, :pick_up_name, :enable_quantity_based_requests]
  #   service = Partners::SectionErrorService.new(error_keys)
  #   sections_with_errors = service.call
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

    # Initializes a new SectionErrorService with a set of error attribute keys.
    #
    # @param error_keys [Array<Symbol>] Array of attribute keys representing the fields with errors.
    def initialize(error_keys)
      @error_keys = error_keys
    end

    # Returns a list of unique sections that contain errors based on the given error keys.
    #
    # @return [Array<String>] An array of section names containing errors.
    def call
      @error_keys.map { |key| section_for_field(key) }.compact.uniq
    end

    private

    # Maps an individual error field to its corresponding section.
    #
    # @param field [Symbol] The field (error key) to map to a section.
    # @return [String, nil] The section name containing the field, or nil if the field has no associated section.
    def section_for_field(field)
      SECTION_FIELD_MAPPING.each do |section, fields|
        return section.to_s if fields.include?(field)
      end
      nil
    end
  end
end
