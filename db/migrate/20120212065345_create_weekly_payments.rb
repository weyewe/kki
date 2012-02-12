class CreateWeeklyPayments < ActiveRecord::Migration
  def change
    create_table :weekly_payments do |t|
      t.integer :week
      t.integer :group_id
      t.integer :membership_id
      t.integer :amount_paid
      
      # the payment will be taken by the debt_collector
      # => then, it will be passed to the cashier 
      t.integer :debt_collector_id
      
      # all the payment will be double checked by cashier 
      # before cashier approval, won't be added to the savings
      # => interest, fine, and principal
      # => Hence, the risk is still with  the field worker
      t.boolean :is_cashier_approved, :default => nil # no decision yet 
      t.integer :cashier_id
      
      t.integer :payment_status, :default => WEEKLY_PAYMENT_STATUS[:unpaid]
      t.integer :less_than_minimum_payment_amount 

      t.timestamps
    end
  end
end
