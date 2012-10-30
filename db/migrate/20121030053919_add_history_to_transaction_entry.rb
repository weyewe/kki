class AddHistoryToTransactionEntry < ActiveRecord::Migration
  def change 
    add_column :transaction_entries, :boolean , :is_deleted, :default => false
    add_column :transaction_entries, :datetime , :deleted_datetime 
  end
end
