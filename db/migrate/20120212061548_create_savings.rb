class CreateSavings < ActiveRecord::Migration
  def change
    create_table :savings do |t|
      t.decimal  :total,      :precision => 10, :scale => 2
      
      t.integer :member_id
      
      t.timestamps
    end
  end
end
