class AddLanguageToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :language, :string, default: 'en', null: false
  end
end
