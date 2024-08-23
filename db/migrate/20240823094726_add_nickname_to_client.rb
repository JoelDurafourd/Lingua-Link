class AddNicknameToClient < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :nickname, :string
  end
end
