class CreateDefaultPayments < ActiveRecord::Migration
  def change
    create_table :default_payments do |t|
      t.integer :group_loan_membership_id
      
      # 10^8 == 99 million rupiah
      # these 3 fields == estimated value, calculated using the algorithm 
      t.decimal :amount_sub_group_share, :precision => 10, :scale => 2 , :default => 0 
      t.decimal :amount_group_share,  :precision => 10, :scale => 2 , :default => 0 
      # only if our guy is defaultee == true 
      t.decimal :amount_of_compulsory_savings_deduction,  :precision => 10, :scale => 2 , :default => 0 
      t.decimal :amount_to_be_shared_with_non_defaultee,  :precision => 10, :scale => 2 , :default => 0 
      
      # total suggested amount, after rounding up to 500 rupiah denomination ( default amount ) 
      t.decimal :total_amount ,  :precision => 10, :scale => 2 , :default => 0 
      
      
      # non defaultee member proposes the amount -> for fairness 
      t.decimal :custom_amount ,  :precision => 10, :scale => 2 , :default => 0 
      # then, during transaction, migrate this custom amount to amount paid. recorded ! 
      
      # actual compulsory savings deduction 
      t.decimal :amount_paid ,  :precision => 10, :scale => 2 , :default => 0 
      t.boolean :is_paid , :default => false 
      
      
      # such loss information is  stored in the group loan 
      
      # in the group loan level. 
      t.decimal :amount_assumed_by_office ,  :precision => 10, :scale => 2 , :default => 0 
      t.boolean :is_assumed_by_office, :default => false # only when member.total_savings < default_payment.total_amount
      
      
      
      t.integer :transaction_id  #to record the default payment resolution 
      # how can we record soft deduction? 
      
      
      
      
      # if the member is non_default, is_defaultee => false
      # if the member defaulted the weekly -payment, is_defaultee = true 
      t.boolean :is_defaultee, :default => false 
      
      
      # do we need approval? it is paid by deducting the compulsory savings 
      t.integer :payment_approver_id 
      t.boolean :is_cashier_approved, :default => false 
      
      t.timestamps
    end
  end
end
