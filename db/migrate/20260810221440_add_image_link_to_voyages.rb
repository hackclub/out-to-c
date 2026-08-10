class AddImageLinkToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :image_link, :string
  end
end
