class CreateSubGroups < ActiveRecord::Migration
  def change
    create_table :sub_groups do |t|
      t.integer :group_loan_id
      t.integer :sub_group_leader_id 

      t.string :name 

      t.timestamps
    end
  end
end
