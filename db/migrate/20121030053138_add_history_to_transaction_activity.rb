class AddHistoryToTransactionActivity < ActiveRecord::Migration
  def change
    add_column :transaction_activities, :integer , :parent_transaction_activity_id , :default => nil 
    add_column :transaction_activities, :boolean , :is_deleted, :default => false  
    add_column :transaction_activities, :datetime , :deleted_datetime 
  end
end
