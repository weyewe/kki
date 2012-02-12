class CreateWeeklyAttendances < ActiveRecord::Migration
  def change
    create_table :weekly_attendances do |t|
      t.integer :week
      t.date    :meeting_date
      t.time    :meeting_time
      
      t.integer :group_id
      t.integer :membership_id
      
      t.boolean :is_attending , :default => nil 
      t.integer :field_worker_id
      

      t.timestamps
    end
  end
end
