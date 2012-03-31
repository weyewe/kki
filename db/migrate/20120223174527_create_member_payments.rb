class CreateMemberPayments < ActiveRecord::Migration
  def change
    create_table :member_payments do |t|
      t.integer :transaction_activity_id # information about the amount, and the field_worker id , and the payee id
      t.integer :weekly_task_id
      
      t.boolean :has_paid, :default => false 
      t.boolean :only_savings, :default => false 
      t.timestamps
    end
  end
end
