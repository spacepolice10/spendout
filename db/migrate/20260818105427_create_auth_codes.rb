class CreateAuthCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_codes do |t|
      t.string :email_address, null: false
      t.string :code, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :auth_codes, :code, unique: true
    add_index :auth_codes, :email_address
    add_index :auth_codes, :expires_at
  end
end
