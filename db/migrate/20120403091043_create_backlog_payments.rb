class CreateBacklogPayments < ActiveRecord::Migration
  def change
    create_table :backlog_payments do |t|
      t.integer :group_loan_id
      t.integer :weekly_task_id
      t.integer :member_payment_id 
      t.integer :member_id 
      t.boolean :is_cleared , :default => false 
      t.integer :backlog_cleared_declarator_id 
      # should be the field_worker 
      
      t.integer :transaction_activity_id_for_backlog_clearance 
      t.boolean :is_group_loan_declared_as_default, :default => false 
      
      t.integer :clearance_period , :default => nil #BACKLOG_CLEARANCE_PERIOD
      
      t.integer :backlog_type, :nil => false # is that penalty payment? is that weekly payment?
      # weekly payment only savings?
      # weekly payment no savings ? declare default 
      
      # cashier needs to approve this, only for the one happening during grace payment period. 
      # marks the time money is returned to the cashier 
      t.integer :backlog_payment_approver_id 
      t.boolean :is_cashier_approved , :default => false 
      t.timestamps
    end
  end
end
