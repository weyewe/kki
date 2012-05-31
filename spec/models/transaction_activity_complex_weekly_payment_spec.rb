require 'spec_helper'

describe TransactionActivity do 
  before(:each) do
    @office = FactoryGirl.create(:cilincing_office)
    @branch_manager_role = FactoryGirl.create(:branch_manager_role)
    @loan_officer_role = FactoryGirl.create(:loan_officer_role)
    @cashier_role = FactoryGirl.create(:cashier_role)
    @field_worker_role = FactoryGirl.create(:field_worker_role)
    @branch_manager = @office.create_user( [@branch_manager_role],
      :email => 'branch_manager@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    @loan_officer = @office.create_user( [@loan_officer_role], 
      :email => 'loan_officer@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    @cashier = @office.create_user( [@cashier_role], 
      :email => 'cashier@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    @field_worker = @office.create_user( [@field_worker_role], 
      :email => 'field_worker@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    
    @group_loan_commune = FactoryGirl.create(:group_loan_commune)
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id )
    
    #
    # => Group loan specific
    #
    
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", 
              :commune_id => @group_loan_commune }, @branch_manager)

    @members.each do |member|
      GroupLoanMembership.create_membership( @loan_officer, member, @group_loan)
    end
    
    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)  # 5 weeks
    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)  # 5 weeks
    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)  # 5 weeks
    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b,
        @group_loan_product_c] 
        
    @group_loan.group_loan_memberships.each do |glm|
      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
    end
    @group_loan.add_assignment(:field_worker, @field_worker)
    @group_loan.add_assignment(:loan_inspector, @branch_manager)
    
    @group_loan.execute_propose_finalization( @loan_officer )
    @group_loan.start_group_loan( @branch_manager )
    
    count = 1
    @group_loan.group_loan_memberships.each do |glm|
      attendance = false
      if count%2 != 0 
        attendance = true 
      end
      count += 1 
      glm.mark_financial_education_attendance( @field_worker, attendance, @group_loan  )
    end
    # we have 4 failed in education attendance
    
    @group_loan.finalize_financial_attendance_summary(@branch_manager)
  end
  
  it "should only allow weekly payment if the loan disbursement has been done + approved by cashier"
  it "can do weekly payment without being limited by the weekly meeting attendance finalization"
  
  context "pre condition for all kind of payment" do 
    # TransactionActivity.create_generic_weekly_payment(
    #         group_loan_membership,
    #         employee,
    #         cash,
    #         savings_withdrawal, 
    #         number_of_weeks,
    #         number_of_backlogs
    # )
    it "should not create transaction if the employee's role is not field worker and" + 
          " that field worker has to be the assigned field worker for the group loan" 
  
    it "should not create transaction if the number of weeks > total weeks remaining  and " +
          " number of weeks < 0  "
    
    it "should not create transaction if the number of backlog payments > actual backlog payment"
    
    it "should not create transaction if savings withdrawal > extra savings (liquid savings)"
    
    it "should not create transaction if cash + savings withdrawal < min_weekly_payment *( number_of_backlog_payments + number_of_weeks)"
  end
  
  
  context "post create" do 
    # test for each the cases 
  end
  
end