class CreateOffices < ActiveRecord::Migration
  def change
    create_table :offices do |t|
      t.string :name
      t.integer :regency_id 

      t.timestamps
    end
  end
end
