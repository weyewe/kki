class CreateCommunes < ActiveRecord::Migration
  def change
    create_table :communes do |t|
      t.string :number
      t.integer :village_id

      t.timestamps
    end
  end
end
