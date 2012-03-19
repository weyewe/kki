class CreateTimelineActivities < ActiveRecord::Migration
  def change
    create_table :timeline_activities do |t|

      t.timestamps
    end
  end
end
