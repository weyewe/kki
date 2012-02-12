class CreateWeeklyPayments < ActiveRecord::Migration
  def change
    create_table :weekly_payments do |t|

      t.timestamps
    end
  end
end
