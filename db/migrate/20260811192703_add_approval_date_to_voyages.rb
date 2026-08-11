class AddApprovalDateToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :approval_date, :date
  end
end
