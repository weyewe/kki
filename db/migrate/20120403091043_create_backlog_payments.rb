class CreateBacklogPayments < ActiveRecord::Migration
  def change
    create_table :backlog_payments do |t|
      t.integer :group_loan_id
      t.integer :weekly_task_id
      t.integer :member_payment_id 
      t.integer :member_id 
      t.boolean :is_cleared , :default => false 
      t.integer :backlog_cleared_declarator_id 
      
      t.integer :backlog_type, :nil => false # is that penalty payment? is that weekly payment?
      t.timestamps
    end
  end
end
