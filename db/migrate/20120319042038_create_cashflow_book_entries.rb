class CreateCashflowBookEntries < ActiveRecord::Migration
  def change
    create_table :cashflow_book_entries do |t|
      t.integer :cashflow_book_id 
      t.integer :entry_type 
      
      # incoming: Capital Infusion, Savings,  Principal Payment, Interest , Fine
      # Deposit, Admin Fee
      
      
      # outgoing: loan disbursement 
      #       : default payment (after deduction from initial deposit)
      # =>    : initial deposit return 
      # =>    : savings withdrawal 
      t.decimal :amount 
      

      t.timestamps
    end
  end
end
