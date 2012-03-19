class CreateTransactionBooks < ActiveRecord::Migration
  def change
    create_table :transaction_books do |t|
      t.integer :member_id 
      t.integer :creator_id 

      t.timestamps
    end
  end
end
