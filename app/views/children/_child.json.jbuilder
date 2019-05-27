json.extract! child, :id, :first_name, :last_name, :date_of_birth, :gender, :child_lives_with, :race, :agency_child_id, :health_insurance, :item_needed_diaperid, :comments, :created_at, :updated_at
json.url child_url(child, format: :json)
