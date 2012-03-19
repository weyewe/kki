class CreateCashflowBooks < ActiveRecord::Migration
  def change
    create_table :cashflow_books do |t|
      t.integer :office_id 
      t.decimal :total_incoming_to_date
      t.decimal :total_outgoing_to_date 

      t.timestamps
    end
  end
end
