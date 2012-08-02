require 'spec_helper'

# create group loan, all members are defaulting. 
# check the default loan resolution number after each grace period payment 
# thats it 
describe GroupLoan do
  # output: 8 members, 3 were deactivated due to nonpresence in the setup meeting 
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
    
    
    # CREATE NO PAYMENT / ONLY SAVINGS as weekly payment 
    defaultee_glm_list = @first_sub_group.active_group_loan_memberships[0..1] + @second_sub_group.active_group_loan_memberships[0..1]
    defaultee_glm_id_list = defaultee_glm_list.collect {|x| x.id }
    puts "the list: #{defaultee_glm_id_list}"

    # now we have 4.. each of them only pay once for weekly payment

    @group_loan.active_group_loan_memberships.each do |glm|
      TransactionActivity.create_independent_savings( glm.member,  BigDecimal("20000"), @field_worker )
    end

    @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
      puts "======================\n"*2
      puts "\n\nin week: #{weekly_task.week_number}"
      @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
        # setup 

        # present in the weekly meeting. declaring no payment 
        if defaultee_glm_id_list.include?(glm.id)  #   and [1,2,3].include?(weekly_task.week_number)
          weekly_task.mark_attendance_as_present( glm.member, @field_worker )
          # weekly_task.create_weekly_payment_declared_as_no_payment( glm.member )
          TransactionActivity.create_savings_only_weekly_payment(
            glm.member,
            weekly_task,
            0.3*glm.group_loan_product.grace_period_weekly_payment,
            @field_worker
          )
          next
        end


        member =  glm.member 
        saving_book = member.saving_book
        initial_total_savings                = saving_book.total 
        initial_extra_savings                = saving_book.total_extra_savings
        initial_compulsory_savings           = saving_book.total_compulsory_savings

        glp = glm.group_loan_product



        #  mark member attendance  # the order doesn't matter 
        weekly_task.mark_attendance_as_present( glm.member, @field_worker )
        # do payment 
        weekly_task = @group_loan.currently_executed_weekly_task

        puts "\n++++++++++ pre condition"
        puts "member_id : #{member.id}"

        puts "initial compulsory_savings: #{initial_compulsory_savings}"
        puts "the currently_executed_weekly_task : #{weekly_task.week_number}"
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
                number_of_backlogs
        )

        a.should be_valid 




        saving_book.reload

        final_total_savings      = saving_book.total 
        final_extra_savings      = saving_book.total_extra_savings
        final_compulsory_savings = saving_book.total_compulsory_savings
        diff = final_total_savings - initial_total_savings
        diff_extra_savings = final_extra_savings - initial_extra_savings
        diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings


        # puts "final compulsory_savings: #{final_compulsory_savings}"
        # puts "\n******THE ANALYTICS"
        # puts "glp min_savings : #{glp.min_savings}"
        # puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
        # puts "diff extra_savings: #{diff_extra_savings.to_i}"
        # puts "The amount of diff for member #{member.id}: #{diff}"

        a.should be_valid 


        puts "~~~~~ the assertion"
        diff.should == glp.min_savings
        diff_compulsory_savings.to_i.should == glp.min_savings.to_i
        diff_extra_savings.should == BigDecimal("0")



      end
      weekly_task.close_weekly_meeting(@field_worker)
      weekly_task.close_weekly_payment( @field_worker )
      weekly_task.approve_weekly_payment_collection( @cashier )

      weekly_task.is_weekly_attendance_marking_done.should be_true 
      weekly_task.is_weekly_payment_collection_finalized.should be_true 
      weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
    end

  end # end of before(:each block)
  

  it "should update the amount deducted on every grace loan payment"  do
    
    puts "******INITIAL  SAVINGS DATA*******"
    @group_loan.active_group_loan_memberships.each do |glm|
      puts "THE voluntary savings #{glm.id}: #{glm.member.saving_book.total_extra_savings}"
      puts "THE compulsory savings #{glm.id}: #{glm.member.saving_book.total_compulsory_savings}"
      default_payment = glm.default_payment 
      if default_payment.is_defaultee == true
        puts "is defaultee"
      else
        puts "not defaultee"
      end
      puts "voluntary_savings to be deduced: #{default_payment.amount_of_extra_savings_deduction.to_s}"
      puts "compulsory_savings to be deduced: #{default_payment.amount_of_compulsory_savings_deduction.to_s}"
      
      puts "unpaid grace payment: #{default_payment.unpaid_grace_period_amount.to_s}"
      puts "-------+++++++++-------"
    end
     # get one defaultee 
     default_group_loan_memberships = @group_loan.default_group_loan_memberships 
     puts "**********total default member: #{default_group_loan_memberships.length}"
     
      
     
     puts "\n++++++++++++++ analytics before the grace payment -----------\n" 
     glm = default_group_loan_memberships.first 
     initial_unpaid_grace_period_amount = glm.default_payment.unpaid_grace_period_amount
     puts "OUR GLM: #{glm.id}"
     puts "THE voluntary savings #{glm.id}: #{glm.member.saving_book.total_extra_savings}"
     puts "THE compulsory savings #{glm.id}: #{glm.member.saving_book.total_compulsory_savings}"
     default_payment = glm.default_payment 
     if default_payment.is_defaultee == true
       puts "is defaultee"
     else
       puts "not defaultee"
     end
     puts "voluntary_savings to be deduced: #{default_payment.amount_of_extra_savings_deduction.to_s}"
     puts "compulsory_savings to be deduced: #{default_payment.amount_of_compulsory_savings_deduction.to_s}"
     
     puts "unpaid grace payment: #{default_payment.unpaid_grace_period_amount.to_s}"
     puts "-------+++++++++-------"
     
     
     
     cash = 0.5 * initial_unpaid_grace_period_amount
     
     
     savings_withdrawal = 0.3*initial_unpaid_grace_period_amount
     puts "cash value: #{cash.to_s}"
     puts "savings_withdrawal value: #{savings_withdrawal.to_s}"
     puts "\n Before the grace period payment \n"
     @transaction_activity = TransactionActivity.create_generic_grace_period_payment(
             glm,
             @field_worker,
             cash,
             savings_withdrawal)
      @transaction_activity.should be_valid 
      puts "\n after the grace period payment\n"
    glm.reload
    # puts "FINAL AMOUNT TO BE PAID: #{glm.default_payment.unpaid_grace_period_amount.to_s} "
    difference  = initial_unpaid_grace_period_amount   - glm.default_payment.unpaid_grace_period_amount
    puts "The difference = #{difference.to_s}"
    if cash+savings_withdrawal >= initial_unpaid_grace_period_amount
      difference.should == initial_unpaid_grace_period_amount
    else
      difference.should == cash + savings_withdrawal 
    end
    
    puts "Default Payment: FINAL STATISTIC"
    @group_loan.reload
    default_group_loan_memberships = @group_loan.default_group_loan_memberships 
    
    # how about the compulsory savings deduction and the voluntary savings deduction? 
  end
  #  the amount deduction round up. How? 
  # most likely, will happen to non defaultee -> rounded up 
  
end