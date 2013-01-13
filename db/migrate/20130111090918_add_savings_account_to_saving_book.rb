class AddSavingsAccountToSavingBook < ActiveRecord::Migration
  def change
    add_column :saving_books, :total_savings_account,:decimal , :default => 0,  :precision => 11, :scale => 2
  end
end
