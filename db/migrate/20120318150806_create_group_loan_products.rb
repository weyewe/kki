class CreateGroupLoanProducts < ActiveRecord::Migration
  def change
    create_table :group_loan_products do |t|
      t.integer :creator_id # the creator ID.. if we need to look for responsibility 
      # different office, different group loans 
      # t.decimal :tax_percent, :precision => 6, :scale => 4
      # DETAIL:  A field with precision 8, scale 2 must round to an absolute value less than 10^6.
      
      t.decimal :principal , :precision => 9, :scale => 2 # 10^7 == 10 million ( max value )
      t.decimal :interest, :precision => 9, :scale => 2
      t.decimal :min_savings, :precision => 9, :scale => 2
      t.decimal :admin_fee, :precision => 9, :scale => 2
      t.decimal :initial_savings ,:precision => 9, :scale => 2
      
      t.integer :total_weeks
      
      t.integer :office_id
      t.timestamps
    end
  end
end
