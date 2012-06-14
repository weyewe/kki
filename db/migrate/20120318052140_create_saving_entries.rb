class CreateSavingEntries < ActiveRecord::Migration
  def change
    create_table :saving_entries do |t|

      t.integer :saving_book_id 
      t.integer :saving_entry_code , :nil => false 
      t.integer :saving_action_type, :nil => false 
      t.integer :transaction_entry_id 
      t.decimal :amount ,:precision => 11, :scale => 2 , :default => 0 
      
      
      
      
      t.timestamps
    end
  end
end
