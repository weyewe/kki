require 'spec_helper'

describe TransactionActivity do 
  before(:each) do 
    # we need branch manager
    # we need loan officer
    # we need cashier
    # we need field_worker  
    # we need group_loan
    # we need group_loan_product x 3 
    # we need several members in a given commune 
    # we need these members hooked to the group loan (group_loan_memberships)
    # 
  end
  
  describe "Setup Payment Transaction Activity" do 
    it "is paid by deducting the loan"
    it "can be paid without loan deduction"
    it "can by paid without loan deduction, but the savings withdrawal can't exceed the member's total savings"
    it "is marked as the setup payment transaction "
    
  end
  
  describe "Loan Disbursement Transaction Activity" do
    it "will be executed if the current_user role is cashier" do 
      # glm = Factory.create(:group_loan_membership_1_group_loan_1)
      #     field_worker = Factory.create(:field_worker_office_1)
      #     cashier = Factory.create(:cashier_office_1 )
      #     transaction_activity_1 = TransactionActivity.execute_loan_disbursement( glm , field_worker)
      #     transaction_activity_1.should_not be_valid
      #     
      #     transaction_activity_2 = TransactionActivity.execute_loan_disbursement( glm , cashier)
      #     transaction_activity_2.should be_valid 
      island = FactoryGirl.create(:island)
      puts "the island name : #{island.name}"
      java_island  = FactoryGirl.create(:java_island)
      puts "The java island name : #{java_island.name}"
      puts "kalibaru meaow?"
      
      
      
      kalibaru_village = FactoryGirl.create(:kalibaru_village)
      puts kalibaru_village.class.to_s
      puts "kalibaru villag postal code is #{kalibaru_village.postal_code}"
      
      non_group_loan_commune = FactoryGirl.create(:non_group_loan_commune)
      puts "The number of non_group_loan_commune is: #{non_group_loan_commune.number}"
      
      branch_manager = FactoryGirl.create(:branch_manager)
      branch_manager_2 = FactoryGirl.create(:branch_manager, email: "branch_manager_2@gmail.com")
      puts "The email of branch_manager is #{branch_manager.email}"
      
      cashier = FactoryGirl.create(:cashier)
      cashier_2  = FactoryGirl.create(:cashier, email: "cashier_2@gmail.com")
      
      puts "Total role by now is #{Role.count}"
      Role.all.each do |role|
        puts "The role is #{role.name}"
      end
      
      puts "Total offices of branch managers: #{branch_manager.offices.count }"
      branch_manager.offices.each do |office|
        puts "the office: #{office.name}"
      end
      
      puts "Total branch manager job attachment: #{branch_manager.job_attachments.count}"
      job_attachment = branch_manager.job_attachments.first
      if job_attachment.is_active == true 
        puts "The job attachment is true "
      else
        puts "the job attachment is false "
      end
      
    end
    it "will be executed if the group loan and the user belongs to the same office"
    it "will deduct the disbursement amount if the deposit is done by 'loan deduction scheme'"
    it "will create 2 transaction entries: giving the full amount to the member, 
                  and the member will return the one equal with setup amount "
    
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