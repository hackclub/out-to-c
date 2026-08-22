class AddPrizesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :all_prizes, :string
    add_column :users, :fulfilled_prizes, :string
  end
end
