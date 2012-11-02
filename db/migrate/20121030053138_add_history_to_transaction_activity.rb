class AddHistoryToTransactionActivity < ActiveRecord::Migration
  def change
    add_column :transaction_activities, :parent_transaction_activity_id , :integer ,  :default => nil 
    add_column :transaction_activities, :is_deleted,  :boolean , :default => false    # deleted means that another revision is created.
    # we need to capture the situation of cancel -> the transaction is simply wrong. 
    
   
    
    add_column :transaction_activities,  :deleted_datetime ,:datetime 
  end
end
