class CreateTransactionEntries < ActiveRecord::Migration
  def change
    create_table :transaction_entries do |t|
      t.integer :transaction_book_id 
      t.integer :transaction_entry_code , :nil => false 
      t.integer :transaction_activity_id 
      t.decimal :amount, :default => 0,  :precision => 9, :scale => 2 
      
      t.integer :cashflow_book_entry_id
      t.timestamps
    end
  end
end
