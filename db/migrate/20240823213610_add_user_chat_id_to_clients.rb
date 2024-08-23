class AddUserChatIdToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :user_chat_id, :bigint
  end
end
