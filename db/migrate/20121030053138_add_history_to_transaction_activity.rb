class AddHistoryToTransactionActivity < ActiveRecord::Migration
  def change
    add_column :transaction_activities, :parent_transaction_activity_id , :integer ,  :default => nil 
    add_column :transaction_activities, :is_deleted,  :boolean , :default => false  
    add_column :transaction_activities,  :deleted_datetime ,:datetime 
  end
end
