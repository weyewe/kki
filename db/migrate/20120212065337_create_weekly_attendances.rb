class CreateWeeklyAttendances < ActiveRecord::Migration
  def change
    create_table :weekly_attendances do |t|

      t.timestamps
    end
  end
end
