class AddTotalSecondsToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :total_seconds, :integer
  end
end
