class AddLinePhotoUrlToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :photo_url, :string
  end
end
