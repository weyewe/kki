class CreateRegencies < ActiveRecord::Migration
  def change
    create_table :regencies do |t|
      t.string :name
      t.integer :province_id

      t.timestamps
    end
  end
end
