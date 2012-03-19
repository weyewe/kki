class CreateSavingEntries < ActiveRecord::Migration
  def change
    create_table :saving_entries do |t|

      t.integer :saving_book_id 
      t.integer :saving_entry_code , :nil => false 
      t.decimal :amount 
      
      t.timestamps
    end
  end
end
