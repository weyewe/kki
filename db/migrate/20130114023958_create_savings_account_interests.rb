class CreateSavingsAccountInterests < ActiveRecord::Migration
  def change
    create_table :savings_account_interests do |t|
      t.integer :office_id 
      
      t.decimal :total_interest_given , :default => 0, :precision =>11, :scale => 2 # 10^9
      t.decimal :annual_interest_rate , :default => 0, :precision =>  5, :scale => 2  # 100.00 
      
      
      # the branch manager creates savings_account_interests
      t.boolean :is_started , :default => false 
      # then, he confirm it.. the calculation is performed by background task
      
      # when all members has been calculated. that's it. FINISHED! 
      t.boolean :is_finished , :default => false  
      
      
      t.timestamps
    end
  end
end


