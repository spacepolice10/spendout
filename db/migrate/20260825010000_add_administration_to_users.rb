class AddAdministrationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_digest, :string
    add_column :users, :role, :integer, default: 0, null: false
    add_check_constraint :users, "role IN (0, 1)", name: "users_role_valid"
  end
end
