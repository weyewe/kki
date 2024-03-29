class CreateWeeklyTasks < ActiveRecord::Migration
  def change
    create_table :weekly_tasks do |t|
      t.integer :group_loan_id

      t.integer :week_number 
      
      t.datetime :weekly_attendance_marking_done_time 
      t.boolean :is_weekly_attendance_marking_done , :default => false 
      t.integer :attendance_closer_id  
      t.integer :group_loan_id
      
      t.datetime :weekly_payment_collection_done_time 
      t.boolean :is_weekly_payment_collection_finalized, :default => false 
      t.integer :weekly_payment_collection_finalizer_id   
      
      # t.decimal :total_cash_received , :default => 0, :precision => 9, :scale => 2 #10^7 = 9.999.999 >> about 10 million rupiah
      
      
      # cashier approval 
      t.boolean :is_weekly_payment_approved_by_cashier, :default => false
      t.integer :weekly_payment_approver_id 
      t.timestamps
    end
  end
end
