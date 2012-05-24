class CreateSavingBooks < ActiveRecord::Migration
  def change
    create_table :saving_books do |t|
      t.decimal  :total, :default => 0,  :precision => 11, :scale => 2 # max value= 10^9 = 999.9999 million rupiah 
      
      
      t.decimal  :total_compulsory_savings, :default => 0,  :precision => 11, :scale => 2 # max value= 10^9 = 999.9999 million rupiah 
      t.decimal  :total_extra_savings, :default => 0,  :precision => 11, :scale => 2 # max value= 10^9 = 999.9999 million rupiah 
      
      t.integer :member_id
      
      
      

      t.timestamps
    end
  end
end
