class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.string :lineid
      t.string :phone_number
      t.string :name

      t.timestamps
    end
  end
end
