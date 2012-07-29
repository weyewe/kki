class CreateMemberPayments < ActiveRecord::Migration
  # used to record member payment activity during group loan cycle
  # 
  def change
    create_table :member_payments do |t|
      t.integer :transaction_activity_id # information about the amount, and the field_worker id , and the payee id
      t.integer :weekly_task_id # on which week, did the payment took place
      t.integer :member_id 
      
      # has_paid acts only as indicator whether there is cash exchanging hands 
      # and it is useless. we are not using it
      # cash passed is useless as well, we are not using it 
      # always check the transaction activity
      t.boolean :has_paid, :default => false 
      t.boolean :only_savings, :default => false 
      t.boolean :no_payment , :default => false 
      
      t.boolean :only_extra_savings , :default => false  # more payment
      
      t.decimal :cash_passed , :default => 0, :precision => 9, :scale => 2 #10^7 = 9.999.999 
      
      # if not weekly payment, the week number is nil 
      # what about backlog, is that nil 
      t.integer :week_number  # on the payment, which week number was it? 
      
      t.boolean :is_independent_weekly_payment, :default => false
      
      
      t.timestamps
    end
  end
end
