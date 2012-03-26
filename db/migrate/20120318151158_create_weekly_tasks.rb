class CreateWeeklyTasks < ActiveRecord::Migration
  def change
    create_table :weekly_tasks do |t|
      t.integer :group_loan_id 
      t.integer :total_attendance
      t.decimal :total_payment_amount 
      
       
      

      t.timestamps
    end
  end
end
