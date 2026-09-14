class AddFraudApprovedByToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :fraud_approved_by, :string
  end
end
