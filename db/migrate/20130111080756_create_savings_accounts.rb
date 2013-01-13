class CreateSavingsAccounts < ActiveRecord::Migration
  def change
    create_table :savings_accounts do |t|

      t.timestamps
    end
  end
end
