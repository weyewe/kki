class CreateGeoScopes < ActiveRecord::Migration
  def change
    create_table :geo_scopes do |t|
      t.integer :office_id
      t.integer :subdistrict_id

      t.timestamps
    end
  end
end
