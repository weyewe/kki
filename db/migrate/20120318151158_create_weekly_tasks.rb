class CreateWeeklyTasks < ActiveRecord::Migration
  def change
    create_table :weekly_tasks do |t|

      t.timestamps
    end
  end
end
