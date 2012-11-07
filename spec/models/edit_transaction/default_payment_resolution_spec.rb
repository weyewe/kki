require 'spec_helper'

describe GroupLoan do
  
  puts " I want to live forever\n"
  
  before(:each) do
    puts " In the before each"
    @office = FactoryGirl.create(:cilincing_office)
    @branch_manager_role = FactoryGirl.create(:branch_manager_role)
    @loan_officer_role = FactoryGirl.create(:loan_officer_role)
    @cashier_role = FactoryGirl.create(:cashier_role)
    @field_worker_role = FactoryGirl.create(:field_worker_role)
    puts "after creating the role"
    
    puts "office is oK " if not @office.nil?
    puts "branch manager  role is oK " if not @branch_manager_role.nil?
    puts "loan officer role  is oK " if not @loan_officer_role.nil?
    puts "cashier is role oK " if not @cashier_role.nil?
    puts "field worker  role is oK " if not @field_worker_role.nil?
    
  
    
    @branch_manager = @office.create_user( [@branch_manager_role],
      :email => 'branch_manager@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    
    puts "BM is in deep shit" if @branch_manager.nil?
    puts "The BM stat: #{@branch_manager}"
    
    puts "bm is ok" if not @branch_manager.nil? 
    
    
    @loan_officer = @office.create_user( [@loan_officer_role], 
      :email => 'loan_officer@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    
    puts "loan officer is ok" if not @loan_officer.nil?
    puts "Loan officer id = #{@loan_officer.id }"
    
    
    @cashier = @office.create_user( [@cashier_role], 
      :email => 'cashier@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    puts "cashier is ok" if not @cashier.nil?
     puts "cashier id = #{@cashier.id }"
    
    
    @field_worker = @office.create_user( [@field_worker_role], 
      :email => 'field_worker@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    
    puts "field worker is ok" if not @field_worker.nil?
    puts "field worker id = #{@field_worker.id }"
    
    @group_loan_commune = FactoryGirl.create(:group_loan_commune)
    #this shit will trigger the creation of kalibaru village, cilincing subdistrict 
    
    # @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
    #          :commune_id => @group_loan_commune }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    
    puts "group loan commune is OK" if not @group_loan_commune.nil?
    
    # puts "Loan officer id: #{@loan_officer.id}"
    #   puts "GroupLoan Commune id: #{@group_loan_commune.id}"
    #   puts "Office  id: #{@office.id}"
    #   
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 10, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id )
     
    
    
    puts "we are in the creation of seeds members. Total member #{@members.count}\n"*10
     
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
       :commune_id => @group_loan_commune }, @branch_manager)
       
       
    @members.each do |member|
      GroupLoanMembership.create_membership( @loan_officer, member, @group_loan)
    end
    
    @group_loan.add_assignment(:field_worker, @field_worker)
    @group_loan.add_assignment(:loan_inspector, @branch_manager)
    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)  # 5 weeks
    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)  # 5 weeks
    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)  # 5 weeks
    
    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b,
        @group_loan_product_c]
        
        
    # create the subcription 
    @group_loan.group_loan_memberships.each do |glm|
      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
    end
    
    
    # create the subgroup 
    sub_group_count = 2 
    SubGroup.set_sub_groups( @group_loan, sub_group_count )
    @first_sub_group = @group_loan.sub_groups[0]
    @second_sub_group =  @group_loan.sub_groups[1]
    
    # assign the member to the subgroup 
    
    count = 0 
    @members.each do |member|
      if count%2 == 0 
        @first_sub_group.add_member( member )
      elsif count%2 == 1 
        @second_sub_group.add_member( member )
      end
      count = count + 1 
    end
    
    
    # propose group loan start
    @group_loan.execute_propose_finalization( @loan_officer )
    
    # start group loan
    @group_loan.start_group_loan( @branch_manager )
    
    # financial education attendance marking
    
    # => mark the financial education attendance 
    @first_glm = @first_sub_group.group_loan_memberships.order("created_at ASC")[0]
    @second_glm = @second_sub_group.group_loan_memberships.order("created_at ASC")[0]
    @third_glm = @first_sub_group.group_loan_memberships.order("created_at ASC")[1]
    
    @group_loan.group_loan_memberships.each do |glm|
      if glm.id == @first_glm.id 
        glm.mark_financial_education_attendance( @field_worker, false , @group_loan  )
      else
        glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
      end
    end
    
    
    # => propose financial education finalization
    @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
    
    # => finalize financial education attendance
    @group_loan.finalize_financial_attendance_summary(@branch_manager)
      
    @group_loan.reload   # refresh the data  from db
    @first_glm.reload
    @second_glm.reload
    @third_glm.reload 
    
    # 1 member is disqualified from group 1  -> didn't attend financial education 
    
    # loan disbursement attendance marking
    
    # => marking the loan disbursement attendance 
    @group_loan.membership_to_receive_loan_disbursement.each do |glm|
      if glm.id == @second_glm.id or glm.id == @third_glm.id
        glm.mark_loan_disbursement_attendance( @field_worker, false, @group_loan  ) 
      end
      
      if glm.id == @first_glm.id 
        next
      end
      
      glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
    end
    
    # THIS IS THE LOGIC NOT CAPTURED  << no rule at all.. let it be. 
    # glm.declare_setup_payment_by_loan_deduction
    # @group_loan.execute_finalize_setup_fee_collection( @field_worker )
    # @group_loan.approve_setup_fee_collection( @cashier )
    
    # => propose loan disbursement attendance finalization
    @group_loan.propose_loan_disbursement_attendance_finalization(@field_worker)
    
    # do the actual disbursement 
    @group_loan.reload 
    # do the actual transaction 
    @group_loan.group_loan_memberships.each do |glm|
      # important.. by default, set it to deduct setup fee from laon disbursment 
      glm.deduct_setup_payment_from_loan = true
      glm.save 
      TransactionActivity.execute_loan_disbursement( glm , @field_worker )
      # the column has_received_disbursement is checked 
    end
    
    # => finalize loan disbursement attendance (+ field worker returning the $$$ )
    @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager )
    
    
    
    # 2 members are disqualified from group 2  -> didn't attend loan disbursement 
    # returning the money from the 2 members weren't attending the disbursement 
    
    # cashier approves loan disbursement 
    @group_loan.execute_finalize_loan_disbursement(@cashier)
    
    
  end # end of before(:each block)
  
  
  context "do payment of 1 week, introduce update. can it be updated?" do 
    before(:each) do
      
      @first_sub_group.reload 
      @second_sub_group.reload 
      
      
      @extra_savings = BigDecimal("10000") 
      
      puts "THIS IS AWESOME SHITE.. total active glm: #{@group_loan.active_group_loan_memberships.count}\n"*10
      puts "Total active glm sub_group 1:  #{@first_sub_group.active_group_loan_memberships.count}"
      puts "Total active glm sub_group 2:  #{@second_sub_group.active_group_loan_memberships.count}"
      @first_glm = @first_sub_group.active_group_loan_memberships.first 
      @second_glm = @second_sub_group.active_group_loan_memberships.first 
       
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task|
        
        @group_loan.active_group_loan_memberships.order("created_at DESC").each do |glm|
          if glm.id == @first_glm.id or glm.id == @second_glm.id
           
            cash = BigDecimal('1000')
           
              
            ActiveRecord::Base.transaction do
              TransactionActivity.create_savings_only_weekly_payment(
                glm.member,
                weekly_task,
                BigDecimal('1000'),
                @field_worker,
                false # not revision transaction
              )
            end
            next 
          end
          
          
          member =  glm.member  
          glp = glm.group_loan_product 

          #  mark member attendance  # the order doesn't matter 
          weekly_task.mark_attendance_as_present( glm.member, @field_worker )

          # TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
          cash_payment = glp.total_weekly_payment
          savings_withdrawal = BigDecimal("0")
          number_of_weeks = 1 
          number_of_backlogs = 0 
          a = TransactionActivity.create_generic_weekly_payment(
            weekly_task, 
                  glm,
                  @field_worker,
                  cash_payment,
                  savings_withdrawal, 
                  number_of_weeks,
                  number_of_backlogs,
                  false
          )

        end # looping across all active_glm
        weekly_task.close_weekly_meeting(@field_worker)
        weekly_task.close_weekly_payment( @field_worker )
        weekly_task.approve_weekly_payment_collection( @cashier )
      end # looping across all weekly task
      
      # by now, it is the grace period payment 
      
      @group_loan.reload 
      # @transaction_activity.approve_grace_period_payment( current_user ) 
    end # end of before(:each)
    
    it 'actual non defaultee is implemented' do  
      @transaction_activity = TransactionActivity.create_generic_grace_period_payment(
              @first_glm,
              @field_worker,
              @first_glm .default_payment.unpaid_grace_period_amount,
              BigDecimal('0'),
              true )
              
      @transaction_activity.approve_grace_period_payment( @cashier ) 
      
      default_payment= @first_glm.default_payment 
      default_payment.is_actual_non_defaultee?.should be_true 
    end
      
    
    context 'new definition of non defaultee is used: non defaultee + cleared defaultee' do
      before(:each) do
        # first glm pays all unpaid grace period in cash.. remnant == the last sucker 
        @initial_total_shared =  @group_loan.default_payment_amount_to_be_shared
        puts "987 initial total shared: #{@initial_total_shared.to_i}"
        @first_glm_total_grace_cash_payment = @first_glm .default_payment.unpaid_grace_period_amount
        puts "987 first_glm payment: #{@first_glm_total_grace_cash_payment.to_i}"
        
        puts "987 second_glm pending payment: #{@second_glm .default_payment.unpaid_grace_period_amount.to_i}"
        
        @transaction_activity = TransactionActivity.create_generic_grace_period_payment(
                @first_glm,
                @field_worker,
                @first_glm_total_grace_cash_payment,
                BigDecimal('0'),
                true )

        @transaction_activity.approve_grace_period_payment( @cashier )
        @group_loan.reload
        @first_glm.reload 
      end
      
      it 'should give group default share to all actual non defaultee' do
        @first_glm .default_payment.unpaid_grace_period_amount.should == BigDecimal('0')
        
        first_default_payment = @first_glm.default_payment
        
        first_default_payment.is_actual_non_defaultee?.should be_true 
        
        first_default_payment.amount_group_share.should_not == BigDecimal('0')
        
      end
      
      
    end # end of context => 'new definition of non defaultee is used: non defaultee + cleared defaultee'
  end 
  
  
end