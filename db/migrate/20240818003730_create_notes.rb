class CreateNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :notes do |t|
      t.text :text
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end
