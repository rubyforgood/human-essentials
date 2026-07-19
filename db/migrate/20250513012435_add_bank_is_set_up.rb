# Migration for https://github.com/rubyforgood/human-essentials/issues/5169
class AddBankIsSetUp < ActiveRecord::Migration[8.0]
  def up
    # new flag for the update to the getting started section
    add_column :organizations, :bank_is_set_up, :boolean, default: false, null: false

    # any organization that has at least one donation site or distribution
    # is considered set up
    Organization
        .left_joins(:donation_sites, :distributions)
        .where.not(donation_sites: { id: nil })
        .or(Organization.where.not(distributions: { id: nil }))
        .distinct
        .update_all( bank_is_set_up: true )

  end

  def down
    remove_column :organizations, :bank_is_set_up
  end
end
