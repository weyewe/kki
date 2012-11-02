class CreateMemberPaymentHistories < ActiveRecord::Migration
  def change
    create_table :member_payment_histories do |t|
      # weekly task can be used to handle group loan, or personal loan , as long as the 
      # payment is paid periodically 
      t.integer :weekly_task_id   # it can be nil
      t.integer :member_id 
      
      # there might be 2 loan products: personal loan and group loan 
      
      t.integer :loan_product_id  # it is the group_loan_id  or personal_loan_id 
      t.integer :loan_product_type # it can be group loan  or personal_loan, or only savings? not related with loan 
      
    
      
      t.decimal :cash , :precision => 11, :scale => 2 , :default => 0 
      t.decimal :savings_withdrawal , :precision => 11, :scale => 2 , :default => 0 
  
      t.integer :number_of_weeks
      t.integer :number_of_backlog  
      t.integer :creator_id 
      
      
      
      # Transaction related to member payment 
      # take note, it can be nil! Reason: no payment declaration in a given periodical payment 
      t.integer :transaction_activity_id  # in a given transaction, it can be nil.. # only for periodic payment 
      # where no weekly payment is made 
      
      
      t.integer :revision_code 
=begin
  8 type of revision code 
  
  1 normal -> normal
  2 only savings -> normal
  3 no payment -> normal 
  
  4 normal -> only savings
  5 only savings -> only savings
  6 no payment -> only savings 
  
  7 normal -> no payment
  8 only savings -> no payment 
=end

      t.integer :payment_phase # 1 for weekly payment, 2 for grace period , 3 for independent payment?
      # for weekly payment, will need the weekly task
      # it is much simpler for grace period and independent payment since there is no 'non payment' declaration  
      # for independent payment, weekly task == nil  
      # for grace period weekly task == nil
      

      t.timestamps
    end
  end
end
