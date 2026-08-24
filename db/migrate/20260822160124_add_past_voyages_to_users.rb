class AddPastVoyagesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :past_voyages, :string
  end
end
