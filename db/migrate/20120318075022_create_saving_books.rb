class CreateSavingBooks < ActiveRecord::Migration
  def change
    create_table :saving_books do |t|
      t.decimal  :total,      :precision => 10, :scale => 2
      
      t.integer :member_id
      

      t.timestamps
    end
  end
end
