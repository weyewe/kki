class AddIsDeletedToSavingEntry < ActiveRecord::Migration
  def change
    add_column :saving_entries, :boolean, :is_deleted, :default => false 
  end
end
