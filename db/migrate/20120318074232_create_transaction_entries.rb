class CreateTransactionEntries < ActiveRecord::Migration
  def change
    create_table :transaction_entries do |t|
      t.integer :transaction_book_id 
      t.integer :transaction_entry_code , :nil => false 
      t.decimal :amount
      
      t.integer :cashflow_book_entry 
      t.timestamps
    end
  end
end
