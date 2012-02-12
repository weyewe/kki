class AddOfficeIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :office_id, :integer, :null => false 
  end
end
