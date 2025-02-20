class AddReceiveEmailOnRequest < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_column :organizations, :receive_email_on_requests, :boolean, default: false, null: false
    end
  end
end
