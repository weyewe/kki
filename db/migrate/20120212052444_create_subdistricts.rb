class CreateSubdistricts < ActiveRecord::Migration
  def change
    create_table :subdistricts do |t|
      t.string :name
      t.integer :regency_id

      t.timestamps
    end
  end
end
