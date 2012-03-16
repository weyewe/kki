class CreateGroupLoans < ActiveRecord::Migration
  def change
    create_table :group_loans do |t|
      t.integer :user_id # the creator ID.. if we need to look for responsibility 
      # different office, different group loans 
      
      t.decimal :principal 
      t.decimal :interest
      t.decimal :min_savings
      t.decimal :admin_fee
      t.decimal :initial_savings 
      
      t.integer :total_weeks
      
      

      t.timestamps
    end
  end
end
