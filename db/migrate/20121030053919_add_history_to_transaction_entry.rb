class AddHistoryToTransactionEntry < ActiveRecord::Migration
  def change 
    add_column :transaction_entries, :is_deleted, :boolean ,  :default => false
    add_column :transaction_entries,  :deleted_datetime , :datetime 
  end
end
