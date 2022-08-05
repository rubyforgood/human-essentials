class FixInvalidTransfers < ActiveRecord::Migration[7.0]
  def change
    Transfer.all.each do |transfer|
      transfer.destroy if transfer.from.nil? || transfer.to.nil?
    end
  end
end
