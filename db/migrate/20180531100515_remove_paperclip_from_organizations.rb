class RemovePaperclipFromOrganizations < ActiveRecord::Migration[5.2]
  def change
    remove_columns :organizations,
                  :logo_file_name,
                  :logo_content_type,
                  :logo_file_size,
                  :logo_updated_at
  end
end
