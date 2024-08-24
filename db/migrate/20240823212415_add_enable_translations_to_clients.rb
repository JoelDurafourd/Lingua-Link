class AddEnableTranslationsToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :enable_translations, :boolean, default: true, null: false
  end
end
