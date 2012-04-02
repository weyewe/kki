class CreateCashflowBooks < ActiveRecord::Migration
  def change
    create_table :cashflow_books do |t|
      t.integer :office_id 
      t.decimal :total_incoming_to_date, :precision => 13, :scale => 2 , :default => 0 
          # 10^11 = 10^2 * 10*9 = 999 * 1 milyar -> 1 Trillion
      t.decimal :total_outgoing_to_date , :precision => 13, :scale => 2 , :default => 0 

      t.timestamps
    end
  end
end
