# db/migrate/[timestamp]_add_state_to_users.rb
class AddStateToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :state, :integer, null: false, default: 0
    add_column :users, :line_user_id, :string
    add_index :users, :line_user_id, unique: true
  end
end
