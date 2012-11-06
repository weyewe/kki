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
    #this shit will trigger the creation of kalibaru village, cilincing subdistrict 
    
    # @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
    #          :commune_id => @group_loan_commune }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 10, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id )
     
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
 
    # => propose loan disbursement attendance finalization
    @group_loan.propose_loan_disbursement_attendance_finalization(@field_worker)
    
    # do the actual disbursement 
    @group_loan.reload 
    # do the actual transaction 
    @group_loan.group_loan_memberships.each do |glm|
      glm.deduct_setup_payment_from_loan = true
      glm.save 
      TransactionActivity.execute_loan_disbursement( glm , @field_worker )
    end
    
    @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager )
    @group_loan.execute_finalize_loan_disbursement(@cashier)
    
    # post conditions => 3 members are out 
  end # end of before(:each block)
  

  context "creating more than 1 payment in a given weekly meeting" do
    before(:each) do 
      @weekly_task = @group_loan.currently_executed_weekly_task

      @first_glm = @group_loan.active_group_loan_memberships.first 
      @first_transaction_activity = TransactionActivity.create_generic_weekly_payment(
                @weekly_task, 
                @first_glm,
                @field_worker,
                @first_glm.group_loan_product.total_weekly_payment + BigDecimal("1000"),
                BigDecimal('0'), 
                1,
                0,
                false)
    end
    
    it 'should produce 1 member payment with related to the transaction' do
      @first_transaction_activity.should be_valid 
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 1
    end
    
    it "should not create another member payment if we do more payment (single week payment). only 1 non approved weekly payment allowed" do
      @second_transaction_activity = TransactionActivity.create_generic_weekly_payment(
                @weekly_task, 
                @first_glm,
                @field_worker,
                @first_glm.group_loan_product.total_weekly_payment + BigDecimal("1000"),
                BigDecimal('0'), 
                1,
                0,
                false)
      @second_transaction_activity.should be_nil 
      # @second_member_payment = MemberPayment.where(:transaction_activity_id => @second_transaction_activity.id ).first
      #       puts "first weekly_task_id : #{@weekly_task.id}"
      #       puts "#{@second_member_payment.inspect}"
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 1 
    end
    
    it "should create another member payment if we do more payment (single week payment). WRONG. no such thing as more payment." do
      @second_transaction_activity = TransactionActivity.create_generic_weekly_payment(
                @weekly_task, 
                @first_glm,
                @field_worker,
                @first_glm.group_loan_product.total_weekly_payment + BigDecimal("1000"),
                BigDecimal('0'), 
                1,
                0, 
                false)
      @second_transaction_activity.should be_nil
      # @second_member_payment = MemberPayment.where(:transaction_activity_id => @second_transaction_activity.id ).first
      # puts "first weekly_task_id : #{@weekly_task.id}"
      # puts "#{@second_member_payment.inspect}"
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 1
    end
    
    it "should create n member payment if we N multiple weeks payment. WRONG! there can only be 1 weekly payment." do
      @second_transaction_activity = TransactionActivity.create_generic_weekly_payment(
                @weekly_task, 
                @first_glm,
                @field_worker,
                2*@first_glm.group_loan_product.total_weekly_payment + BigDecimal("1000"),
                BigDecimal('0'), 
                2,
                0, 
                false )
      @second_transaction_activity.should be_nil  
      # MemberPayment.where(:transaction_activity_id => @second_transaction_activity.id ).
      #                  count.should == 0
  
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 1
    end

    
  end
  
  context "creating more weekly payment on the week that has been paid from previous week" do
    before(:each) do 
      @first_glm = @group_loan.active_group_loan_memberships.first 
      @weekly_task = @group_loan.currently_executed_weekly_task
      
      
      @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
        # setup 

        member =  glm.member 
        saving_book = member.saving_book
        glp = glm.group_loan_product



        #  mark member attendance  # the order doesn't matter 
        @weekly_task.mark_attendance_as_present( glm.member, @field_worker )
      
        cash_payment = glp.total_weekly_payment
        savings_withdrawal = BigDecimal("0")
        number_of_weeks = 1 
        number_of_backlogs = 0 
        if glm.id != @first_glm.id 
          a = TransactionActivity.create_generic_weekly_payment(
              @weekly_task, 
              glm,
              @field_worker,
              cash_payment,
              savings_withdrawal, 
              number_of_weeks,
              number_of_backlogs,
              false)
        else
          a = TransactionActivity.create_generic_weekly_payment(
              @weekly_task, 
              glm,
              @field_worker,
              glp.total_weekly_payment*2 ,
              savings_withdrawal, 
              2,
              number_of_backlogs,
              false)
        end


      end
      @weekly_task.close_weekly_meeting(@field_worker)
      @weekly_task.close_weekly_payment( @field_worker )
      @weekly_task.approve_weekly_payment_collection( @cashier )
      @weekly_task.is_weekly_attendance_marking_done.should be_true 
      @weekly_task.is_weekly_payment_collection_finalized.should be_true 
      @weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
    end
    
    it 'should start with weekly_task.week_number==2 ' do
      @weekly_task = @group_loan.currently_executed_weekly_task
      @weekly_task.week_number.should == 2 
    end
    
    it 'should produce 0 transactions for the weekly task' do
      @weekly_task = @group_loan.currently_executed_weekly_task
      @weekly_task.has_paid_weekly_payment?(@first_glm.member).should be_true 
      
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 0  
    end
    
    it 'should be able to produce more transactions, even if this week is paid last week' do
      @weekly_task = @group_loan.currently_executed_weekly_task
      @weekly_task.has_paid_weekly_payment?(@first_glm.member).should be_true 
      
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 0  
      number_of_weeks = 1
      transaction_activity = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @first_glm.group_loan_product.total_weekly_payment*number_of_weeks ,
          BigDecimal("0"), 
          number_of_weeks,
          0,
          false)
          
      transaction_activity.should be_valid 
      
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 1 
      
    end
    
    it 'should not be able to produce more transactions if exceeds the total allowed number of weeks, even if this week is paid last week' do
      @weekly_task = @group_loan.currently_executed_weekly_task
      @weekly_task.has_paid_weekly_payment?(@first_glm.member).should be_true 
      
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 0  
      number_of_weeks = @first_glm.group_loan_product.total_weeks + 1 
      transaction_activity = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @first_glm.group_loan_product.total_weekly_payment*number_of_weeks ,
          BigDecimal("0"), 
          number_of_weeks,
          0,
          false)
          
      transaction_activity.should be_nil
    end
    
  end
  
  
  context "paying the backlog payment in a given weekly task" do 
    before(:each) do 
      @first_glm = @group_loan.active_group_loan_memberships.first 
      @weekly_task = @group_loan.currently_executed_weekly_task
      
      
      @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
        # setup 

        member =  glm.member 
        saving_book = member.saving_book
        glp = glm.group_loan_product



        #  mark member attendance  # the order doesn't matter 
        @weekly_task.mark_attendance_as_present( glm.member, @field_worker )
      
        cash_payment = glp.total_weekly_payment
        savings_withdrawal = BigDecimal("0")
        number_of_weeks = 1 
        number_of_backlogs = 0 
        if glm.id != @first_glm.id 
          a = TransactionActivity.create_generic_weekly_payment(
              @weekly_task, 
              glm,
              @field_worker,
              cash_payment,
              savings_withdrawal, 
              number_of_weeks,
              number_of_backlogs,
              false)
        else
          a = @weekly_task.create_weekly_payment_declared_as_no_payment(@field_worker, @first_glm.member)
        end


      end
      @weekly_task.close_weekly_meeting(@field_worker)
      @weekly_task.close_weekly_payment( @field_worker )
      @weekly_task.approve_weekly_payment_collection( @cashier )
      @weekly_task.is_weekly_attendance_marking_done.should be_true 
      @weekly_task.is_weekly_payment_collection_finalized.should be_true 
      @weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
    end
    
    it "should have 1 backlog payment" do
      @first_glm.unpaid_backlogs.count.should == 1 
      @weekly_task = @group_loan.currently_executed_weekly_task
      @weekly_task.has_paid_weekly_payment?(@first_glm.member).should be_false
    end
    
    it "should have 2 different transactions if we pay the week payment and backlog payment separately" do
      @weekly_task = @group_loan.currently_executed_weekly_task
      number_of_weeks = 1 
      number_of_backlogs = 1 
      transaction_activity_weekly_payment = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @first_glm.group_loan_product.total_weekly_payment*number_of_weeks ,
          BigDecimal("0"), 
          number_of_weeks,
          0,
          false)
          
      transaction_activity_weekly_payment.should be_valid
          
      transaction_activity_backlog_payment = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @first_glm.group_loan_product.total_weekly_payment*number_of_weeks ,
          BigDecimal("0"), 
          0,
          number_of_backlogs,
          false)
          
      transaction_activity_backlog_payment.should be_nil # the transaction_activity weekly payment has to be approved
      
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 1 
    end
    
    it "should have 1 transaction if we pay the week payment and backlog payment together" do
      @weekly_task = @group_loan.currently_executed_weekly_task
      @group_loan.unpaid_backlogs.count.should == 1 
      number_of_weeks = 1 
      number_of_backlogs = 1 
      transaction_activity  = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @first_glm.group_loan_product.total_weekly_payment*( number_of_weeks + number_of_backlogs )  ,
          BigDecimal("0"), 
          number_of_weeks,
          number_of_backlogs,
          false)
     
          
      transaction_activity.should be_valid
      @group_loan.unpaid_backlogs.count.should == 0 
      @weekly_task.transactions_for_member(@first_glm.member).count.should == 1
      
      #  do extra savings 
      initial_total_savings_value = @first_glm.member.saving_book.total
      initial_extra_savings_value = @first_glm.member.saving_book.total_extra_savings 
      savings_amount = BigDecimal("40000")
      extra_savings_only_transaction = TransactionActivity.create_weekly_extra_savings_only( @weekly_task, 
        @first_glm, @field_worker, savings_amount )
        
      @first_glm.reload
      final_total_savings_value = @first_glm.member.saving_book.total
      final_extra_savings_value = @first_glm.member.saving_book.total_extra_savings 
      
      (final_total_savings_value-initial_total_savings_value).should == savings_amount 
      (final_extra_savings_value-initial_extra_savings_value).should == savings_amount 
      
      
    end
    
    it "should not create transaction with expired weekly task " do
      @first_weekly_task = @group_loan.weekly_tasks.where(:week_number => 1).first
      
      number_of_weeks = 1 
      number_of_backlogs = 1 
      transaction_activity  = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @first_glm.group_loan_product.total_weekly_payment*( number_of_weeks + number_of_backlogs )  ,
          BigDecimal("0"), 
          number_of_weeks,
          number_of_backlogs,
          false)
      
      transaction_activity.should be_nil 
      
    end
    
    it "should not create transaction with future weekly task" do 
      @future = @group_loan.weekly_tasks.where(:week_number => 3).first
      
      number_of_weeks = 1 
      number_of_backlogs = 1 
      transaction_activity  = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @first_glm.group_loan_product.total_weekly_payment*( number_of_weeks + number_of_backlogs )  ,
          BigDecimal("0"), 
          number_of_weeks,
          number_of_backlogs,
          false)
      
      transaction_activity.should be_nil
    end
  end
  
  
  
  
  
end