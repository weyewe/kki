class CreateTransactionActivityHistories < ActiveRecord::Migration
  # to track the changes made on a given transaction activity 
  # there are 2 changes: 
  # 1. transaction change -> changes in cash, savings withdrawal, number of weeks, number of backlogs 
  # 2. member payment change -> changes in type of payment ->
    # only savings, normal, no payment 
  def change
    create_table :transaction_activity_histories do |t|
      t.integer :weekly_task_id 
      # what if there is personal loan? # still paid weekly though.. 
      # group loan has many weekly tasks. 
      # personal loan has many weekly tasks as well.  exact same system 
      t.integer :member_id 
      
      
      t.integer :loan_product_id  # it is the group_loan_id 
      t.integer :loan_product_type # it can be group loan  or personal_loan, or only savings? not related with loan 
      
      t.decimal :cash , :precision => 11, :scale => 2 , :default => 0 
      t.decimal :savings_withdrawal , :precision => 11, :scale => 2 , :default => 0 
      t.integer :number_of_weeks
      t.integer :number_of_backlog_payments 
      t.integer :creator_id 
      
      
      
      # for non weekly payment -> no changes from no transaction to transaction  
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
