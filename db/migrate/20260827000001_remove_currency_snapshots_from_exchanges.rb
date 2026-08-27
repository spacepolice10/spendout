class RemoveCurrencySnapshotsFromExchanges < ActiveRecord::Migration[8.1]
  def change
    remove_column :exchanges, :sender_currency_code, :string, limit: 3, null: false
    remove_column :exchanges, :receiver_currency_code, :string, limit: 3, null: false
  end
end
