class CreateMemberPayments < ActiveRecord::Migration
  def change
    create_table :member_payments do |t|
      t.integer :transaction_activity_id # information about the amount, and the field_worker id , and the payee id
      t.integer :weekly_task_id
      t.integer :member_id 
      
      t.boolean :has_paid, :default => false 
      t.boolean :only_savings, :default => false 
      
      t.boolean :no_payment , :default => false 
      
      
      t.decimal :cash_passed , :default => 0, :precision => 9, :scale => 2 #10^7 = 9.999.999 
      
      
      t.timestamps
    end
  end
end
