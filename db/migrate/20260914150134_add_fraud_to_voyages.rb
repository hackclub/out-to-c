class AddFraudToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :fraud_approved, :boolean
    add_column :voyages, :fraud_suspected, :boolean
  end
end
