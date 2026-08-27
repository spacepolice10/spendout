class RenameExchangeParticipants < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :exchanges, name: :exchanges_parent_amount_positive
    remove_check_constraint :exchanges, name: :exchanges_child_amount_positive

    rename_column :exchanges, :parent_source_id, :sender_source_id
    rename_column :exchanges, :child_source_id, :receiver_source_id
    rename_column :exchanges, :parent_amount, :sender_amount
    rename_column :exchanges, :child_amount, :receiver_amount
    rename_column :exchanges, :parent_currency_code, :sender_currency_code
    rename_column :exchanges, :child_currency_code, :receiver_currency_code

    add_check_constraint :exchanges, "sender_amount > 0", name: :exchanges_sender_amount_positive
    add_check_constraint :exchanges, "receiver_amount > 0", name: :exchanges_receiver_amount_positive
  end

  def down
    remove_check_constraint :exchanges, name: :exchanges_sender_amount_positive
    remove_check_constraint :exchanges, name: :exchanges_receiver_amount_positive

    rename_column :exchanges, :sender_source_id, :parent_source_id
    rename_column :exchanges, :receiver_source_id, :child_source_id
    rename_column :exchanges, :sender_amount, :parent_amount
    rename_column :exchanges, :receiver_amount, :child_amount
    rename_column :exchanges, :sender_currency_code, :parent_currency_code
    rename_column :exchanges, :receiver_currency_code, :child_currency_code

    add_check_constraint :exchanges, "parent_amount > 0", name: :exchanges_parent_amount_positive
    add_check_constraint :exchanges, "child_amount > 0", name: :exchanges_child_amount_positive
  end
end
