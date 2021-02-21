class AddPartnerToFamily < ActiveRecord::Migration[5.2]
  def change
    add_reference :families, :partner, foreign_key: true
  end
end
