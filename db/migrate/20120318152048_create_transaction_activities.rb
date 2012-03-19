class CreateTransactionActivities < ActiveRecord::Migration
  def change
    create_table :transaction_activities do |t|
      t.integer :creator_id # the user who executed the transaction 
      t.decimal :total_transaction_amount # 
      
      # from employee to member? like returning deposit, or savings withdrawal 
      # from member to employee -> Payment of weekly task 
      t.integer :from_id 
      t.integer :to_id   
      
      # we need to know at which office this transaction is happening 
      t.integer :office_id 
      
      # 1 => from company to member   -> from_id is the employee_id, to_id is the member_id 
      # 2 => from member to company   -> from_id is the member_id, to_id is the employee_id 
      t.integer :transaction_case 
      
      
      
      t.timestamps
    end
  end
end
