module Partners
  module ProfileHelper
    # Returns an array of filenames that are attached to the profile but not persisted.
    # This is to display to the user that the system remembers their file selections
    # even if there was a form validation error.
    # The method returns a JSON string (an array of filenames) to be used in a Stimulus controller.
    def attached_but_not_persisted_file_names(profile)
      filenames = profile.documents.attachments
        .select { |att| !att.persisted? }
        .map { |att| att.blob.filename.to_s }

      filenames.to_json
    end

    # Returns true if at least one document attachment is actually persisted
    def has_persisted_documents?(profile)
      profile.documents.attachments.any?(&:persisted?)
    end
  end
end
