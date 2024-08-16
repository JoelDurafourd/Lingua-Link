class AddFieldsToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :destination, :string
    add_column :messages, :timestamp, :string
    add_column :messages, :message_id, :string
    add_column :messages, :quote_token, :string
    add_column :messages, :original_text, :string # contents
    add_column :messages, :translated_text, :string # contents
    add_column :messages, :source_type, :string
    add_column :messages, :source_user_id, :string
    add_column :messages, :reply_token, :string
    add_column :messages, :uuid, :string
    add_index :messages, :uuid, unique: true
  end
end
