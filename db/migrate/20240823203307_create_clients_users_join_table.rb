class CreateClientsUsersJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :clients, :users do |t|
      t.index [:client_id, :user_id], unique: true # Ensures unique associations
      t.index [:user_id, :client_id] # Allows reverse lookup

      # Additional fields can be added here if needed
      # For example:
      # t.datetime :added_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
