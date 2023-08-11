class CleanUpOldFields < ActiveRecord::Migration[7.0]
  def change
    remove_columns :partner_profiles,
                   :evidence_based_description,
                   :program_client_improvement,
                   :incorporate_plan,
                   :turn_away_child_care,
                   :responsible_staff_position,
                   :trusted_pickup,
                   :serve_income_circumstances,
                   :internal_db,
                   :maac,
                   :pick_up_method,
                   :ages_served,
                   :name,
                   :partner_status,
                   :status_in_diaper_base,
                   :application_data,
                   :distributor_type

  end
end
