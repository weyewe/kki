class CreateMemberAttendances < ActiveRecord::Migration
  def change
    create_table :member_attendances do |t|
      t.integer :weekly_task_id 
      # the weekly meeting SOP: 1. marking attendance
      # the field_worker has to click the Close Marking Attendance Button
      # in order to collect payment 
      # the act of marking attendance => mark the is_on_time to be true 
      # and marking the is_present to be true 
      # t.boolean :is_on_time, :default => false  
      
      # fuck, it is either is present or not present
      # t.boolean :is_present , :default => false 
      t.integer :attendance_status, :default => ATTENDANCE_STATUS[:unmarked] 
      
      
      # so, say that a member is late, marked as is_present => false
      # but, the member paid $$$. What does it do? it just do payment. nothing else
      t.integer :attendance_marker_id 
      t.integer :member_id 
      t.timestamps
    end
  end
end
