class CreateMemberPayments < ActiveRecord::Migration
  def change
    create_table :member_payments do |t|
      t.integer :member_id 
      t.integer :amount 
      t.integer :payment_id 
      t.integer :user_id # the one who received the $$
    

      t.timestamps
    end
  end
end
