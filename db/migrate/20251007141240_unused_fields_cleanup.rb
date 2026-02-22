class UnusedFieldsCleanup < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      # removing columns that were removed from  user interface in 2022
      remove_column :partner_profiles,  :evidence_based_description
      remove_column :partner_profiles,  :turn_away_child_care
      remove_column :partner_profiles,  :incorporate_plan
      remove_column :partner_profiles,  :responsible_staff_position
      remove_column :partner_profiles,  :trusted_pickup
      remove_column :partner_profiles,  :serve_income_circumstances
      remove_column :partner_profiles,  :internal_db
      remove_column :partner_profiles,  :maac
      remove_column :partner_profiles,  :pick_up_method
      remove_column :partner_profiles,  :ages_served
      # Note:  "verified successes of program" was listed in the columns to be removed, but not found in the db  I think it's program_client_improvement, below
      # These three columns were noted as "ignored columns" in profile.rb, and check out as far as no recent data in production (application_data and distributor_type are empty,
      # and program_client_improveement has no data since 2022)
      remove_column :partner_profiles,  :application_data
      remove_column :partner_profiles,  :distributor_type
      remove_column :partner_profiles, :program_client_improvement
    end

  end
end
