class CreateDefaultPayments < ActiveRecord::Migration
  def change
    create_table :default_payments do |t|
      t.integer :group_loan_membership_id
      t.decimal :amount_sub_group_share, :precision => 10, :scale => 2 , :default => 0 
      # 10^8 == 99 million rupiah
      t.decimal :amount_group_share,  :precision => 10, :scale => 2 , :default => 0 
      
      t.decimal :total_amount ,  :precision => 10, :scale => 2 , :default => 0 
      
      
      t.decimal :amount_paid ,  :precision => 10, :scale => 2 , :default => 0 
      t.boolean :is_paid , :default => false 
      t.integer :transaction_id  #to record the default payment resolution 
      # if the member is non_default, is_defaultee => false
      # if the member defaulted the weekly -payment, is_defaultee = true 
      t.boolean :is_defaultee, :default => false 
      
      
      t.timestamps
    end
  end
end
