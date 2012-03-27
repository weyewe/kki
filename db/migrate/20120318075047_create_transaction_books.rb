class CreateTransactionBooks < ActiveRecord::Migration
  def change
    create_table :transaction_books do |t|
      t.integer :member_id 
      t.integer :creator_id 
      
      t.decimal  :total, :default => 0,  :precision => 12, :scale => 2 # max value= 10^10 = 9.999 billion rupiah 
      

      t.timestamps
    end
  end
end
