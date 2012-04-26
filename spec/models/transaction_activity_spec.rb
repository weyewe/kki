require 'spec_helper'

describe TransactionActivity do 
  before(:each) do 
    # we need current_user
    # we need group_loan_membership
    # we need the member 
    # yeah, it is a pain in the ass, but have to be done. Just do it. bite the bullet
    # factories.rb ? create the needed shite
  end
  
  describe "Setup Payment Transaction Activity" do 
  
    it "is paid by deducting the loan"
    it "can be paid without loan deduction"
    it "can by paid without loan deduction, but the savings withdrawal can't exceed the member's total savings"
    it 'is marked as the setup payment transaction '
  end
  
  describe "Loan Disbursement Transaction Activity" do
    it "will only do the transaction if the officer is a field worker 
              and attached to the office where group_loan_membership is declared"
    it "records transaction amount with virtual transaction from member to the office for setup payment"
    it "records the soft deduction from loan amount for setup payment"
  end
  
  describe "Weekly Loan Payment Transaction Activity" do 
    it "records principal, compulsory savings, and interest payment"
    it "has minimum amount of the group_loan_product minimum amount"
  end
  
  describe "Backlog Payment Transaction Activity" do 
    it "records the principal, compulsory savings, and interest payment"
    it "might contain the penalty payment for being late"
  end
  
  it "is storing reference to the loan type, either group_loan or backlog payment, or single loan"
  it "has loan amount that is equal to the amoung of money exchanging hands from member to employee or vice versa"
  it "won't create double transaction activities "
  
  describe "Group Loan Default Resolution Transaction Activity" do
    it 'records the payment from all member, the minimum denomination is 500 rupiah (up rounded)'
    it "records the excess due to rounding as rounding payment"
  end
end