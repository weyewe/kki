class AddIsDeletedToSavingEntry < ActiveRecord::Migration
  def change
    add_column :saving_entries, :is_deleted, :boolean,  :default => false 
  end
end
