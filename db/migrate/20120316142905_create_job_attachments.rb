class CreateJobAttachments < ActiveRecord::Migration
  def change
    create_table :job_attachments do |t|
      t.integer :office_id 
      t.integer :user_id
      t.boolean :is_active , :default => false 

      t.timestamps
    end
  end
end
