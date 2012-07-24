class AddApprovalToTransactionActivity < ActiveRecord::Migration
  def change
    add_column :transaction_activities, :is_approved, :boolean, :default => false 
    add_column :transaction_activities, :approver_id , :integer 
  end
end
