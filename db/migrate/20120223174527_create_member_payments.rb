class CreateMemberPayments < ActiveRecord::Migration
  def change
    create_table :member_payments do |t|
      t.integer :transaction_activity_id # information about the amount, and the field_worker id , and the payee id
      t.integer :weekly_payment_id
      t.timestamps
    end
  end
end
