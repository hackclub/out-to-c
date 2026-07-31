class AddHcaTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :hca_token, :string
  end
end
