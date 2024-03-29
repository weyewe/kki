require 'spec_helper'

# things to do: verify the post condition. can we assume that it is correct? %__% 
# can't assume. 
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
    #          :commune_id => @group_loan_commune.id }, @branch_manager)
    
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
       :commune_id => @group_loan_commune.id }, @branch_manager)
       
       
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
  
 
  context "start doing the weekly transaction. basic payment all the way" do 
    context "start with normal " do 
      before(:each) do 
        @weekly_task = @group_loan.weekly_tasks.first  
        
        @first_glm = @group_loan.active_group_loan_memberships[0] 
          
        @member =  @first_glm.member  

        
         
       @weekly_task.mark_attendance_as_present( @first_glm.member, @field_worker )
        # do payment 
        @weekly_task = @group_loan.currently_executed_weekly_task
        @glp = @first_glm.group_loan_product
         
        @cash_payment = @glp.total_weekly_payment
        @savings_withdrawal = BigDecimal("0")
        @number_of_weeks = 1 
        @number_of_backlogs = 0 
        
        @initial_compulsory_savings = @member.saving_book.total_compulsory_savings
        @initial_voluntary_savings = @member.saving_book.total_extra_savings
        # before the weekly payment 
        # so, if the weekly payment is cancelled, no effect to these 2 
        
        @first_transaction = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
                @first_glm,
                @field_worker,
                @cash_payment,
                @savings_withdrawal, 
                @number_of_weeks,
                @number_of_backlogs,
                false # is revision 
        )
      end
      
      
      
      ####
      #  Generic normal pre condition: will rollback if some shit is broken
      #  Test the post condition! 
      ####
      it 'shouldnt raise ActiveRecord:Rollback on wrong input if it is the wrong metric' do
        TransactionActivity.where(:loan_type =>  LOAN_TYPE[:group_loan],
          :member_id => @member.id, :is_deleted => true).count.should == 0 
        
         
        lambda {TransactionActivity.update_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          BigDecimal("0"),
          BigDecimal("-50000"), 
          @number_of_weeks,
          @number_of_backlogs   
        )}.should raise_error ActiveRecord::Rollback
        
        
      end
      
      it 'should cancel all transaction in case of rollback (normal-> normal)' do 
        TransactionActivity.where(:loan_type =>  LOAN_TYPE[:group_loan],
          :member_id => @member.id, :is_deleted => true).count.should == 0 
        
        
        ActiveRecord::Base.transaction do
          TransactionActivity.update_generic_weekly_payment(
            @weekly_task, 
            @first_glm,
            @field_worker,
            BigDecimal("0"),
            BigDecimal("-50000"), 
            @number_of_weeks,
            @number_of_backlogs   
          )
        end
        
        TransactionActivity.where(:loan_type =>  LOAN_TYPE[:group_loan],
          :member_id => @member.id, :is_deleted => true).count.should == 0 
        
      end
      
      it 'should create the first transaction and one member history' do
        @first_transaction.should be_valid 
         
        
         MemberPaymentHistory.where(
            :weekly_task_id    => @weekly_task.id,
            :member_id => @member.id , 
            :loan_product_id => @group_loan.id, 
            :loan_product_type => LOAN_PRODUCT[:group_loan]
          ).count == 1
          
          
        MemberPaymentHistory.where(
          :transaction_activity_id => @first_transaction.id 
        ).first.revision_code.should == REVISION_CODE[:original_normal] 
      end
      
      #testing the post condition after normal -> normal 
      it 'should create the correct amount of savings( compulsory + voluntary ) and backlog payment' do
        
        extra_savings = BigDecimal("5000")
         
        
        ActiveRecord::Base.transaction do
          @second_transaction = TransactionActivity.update_generic_weekly_payment(
            @weekly_task, 
            @first_glm,
            @field_worker,
            @cash_payment*2 +extra_savings ,
            BigDecimal('0'), 
            @number_of_weeks + 1 ,
            @number_of_backlogs   
          )
        end
        
        # check the savings diff: compulsory and extra (voluntary)
        
        @member.reload
        @final_compulsory_savings = @member.saving_book.total_compulsory_savings
        @final_voluntary_savings = @member.saving_book.total_extra_savings
        
        @compulsory_savings_diff = @final_compulsory_savings - @initial_compulsory_savings 
        @compulsory_savings_diff.should == 2*@first_glm.group_loan_product.min_savings
        
        (@final_voluntary_savings - @initial_voluntary_savings).should ==  extra_savings 
        
        # check the member payment 
        MemberPayment.where(:transaction_activity_id => @second_transaction.id).count.should == 2 
        
        # check the backlog payment 
      end
      
      it "should create 2 history if normal -> normal " do
        @second_transaction = TransactionActivity.update_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @cash_payment + BigDecimal('1000'),
          @savings_withdrawal, 
          @number_of_weeks,
          @number_of_backlogs   
        )


        @second_transaction.should be_valid 
        @first_transaction.reload
        @first_transaction.is_deleted.should be_true 


        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan]
        ).count == 2 

        last_member_payment_history =  MemberPaymentHistory.where(
          :transaction_activity_id => @second_transaction.id 
        ).first 
        last_member_payment_history.revision_code == REVISION_CODE[:normal][:normal]
      end
      
      
      it 'should cancel all transaction in case of rollback (normal-> only savings)' do 
        TransactionActivity.where(:loan_type =>  LOAN_TYPE[:group_loan],
          :member_id => @member.id, :is_deleted => true).count.should == 0 
        
        ActiveRecord::Base.transaction do
          @transaction_activity = TransactionActivity.update_savings_only_weekly_payment(
            @member,
            @weekly_task,
            BigDecimal("0"),
            @field_worker
          )
        end
        
        
      
        TransactionActivity.where(:loan_type =>  LOAN_TYPE[:group_loan],
          :member_id => @member.id, :is_deleted => true).count.should == 0 
        
      end
      
      
      it 'check the post condition normal -> only savings' do
        savings_amount = BigDecimal("10000")
        @second_transaction =  TransactionActivity.update_savings_only_weekly_payment(
          @member,
          @weekly_task,
          savings_amount,
          @field_worker 
        )


        @second_transaction.should be_valid 
        @first_transaction.reload
        @first_transaction.is_deleted.should be_true 


        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan]
        ).count == 2 

        last_member_payment_history =  MemberPaymentHistory.where(
          :transaction_activity_id => @second_transaction.id 
        ).first 
        last_member_payment_history.revision_code == REVISION_CODE[:normal][:only_savings]
        
        
        
        member_payment = MemberPayment.where(:transaction_activity_id => @second_transaction.id  ).first
        BacklogPayment.where(:member_payment_id => member_payment.id ).count.should == 1 
        member_payment.only_savings_payment?.should be_true 
        
        @member.reload 
        @final_compulsory_savings = @member.saving_book.total_compulsory_savings
        @final_voluntary_savings = @member.saving_book.total_extra_savings
        
        @compulsory_savings_diff = @final_compulsory_savings - @initial_compulsory_savings 
        @compulsory_savings_diff.should == BigDecimal('0')
        
        (@final_voluntary_savings - @initial_voluntary_savings).should ==  savings_amount
        
      end
      
      it 'should create 2 history if normal -> no payment' do 
        
        ActiveRecord::Base.transaction do
           @member_payment = @weekly_task.update_weekly_payment_declared_as_no_payment(@field_worker , @member)  
        end
        
        
       
        
        @member_payment.no_payment?.should be_true 
         
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan] 
        ).count == 2
        
        
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan],
          :revision_code =>  REVISION_CODE[:normal][:no_payment] 
        ).count == 1
        
        @first_transaction.reload
        @first_transaction.is_deleted.should be_true 
        
        
        @member.reload 
        @saving_book = @member.saving_book 
        @final_compulsory_savings = @saving_book.total_compulsory_savings
        @final_voluntary_savings = @saving_book.total_extra_savings
        
        
        
        # diff in compulsory savings
        @compulsory_savings_diff = @final_compulsory_savings - @initial_compulsory_savings
      
        @compulsory_savings_diff.should == BigDecimal("0")
        
        # diff in voluntary savings
        (@final_voluntary_savings - @initial_voluntary_savings).should ==  BigDecimal("0")
        
 
        
        # diff in backlog payment 
        BacklogPayment.where(:member_id => @member.id, :is_cleared => false ).count.should == 1 
        
      end
    end # end of start with normal 
    
    
    context "start with only savings " do 
      before(:each) do 
        @weekly_task = @group_loan.weekly_tasks.first  
        
        @first_glm = @group_loan.active_group_loan_memberships[0] 
          
        @member =  @first_glm.member  

        
         
       @weekly_task.mark_attendance_as_present( @first_glm.member, @field_worker )
        # do payment 
        @weekly_task = @group_loan.currently_executed_weekly_task
        @glp = @first_glm.group_loan_product
         
        @cash_payment = @glp.total_weekly_payment
        @savings_withdrawal = BigDecimal("0")
        @number_of_weeks = 1 
        @number_of_backlogs = 0 
        
        @initial_compulsory_savings = @member.saving_book.total_compulsory_savings 
        @initial_voluntary_savings = @member.saving_book.total_extra_savings 
        
        @savings_amount = @cash_payment * 0.5   
        ActiveRecord::Base.transaction do
          @first_transaction =  TransactionActivity.create_savings_only_weekly_payment(
            @member,
            @weekly_task,
            @savings_amount,
            @field_worker,
            false # revision transaction
          )
        end
        
        puts "120987 initial savings amount: #{@savings_amount.to_i}"
        @member.reload 
        @first_compulsory_savings = @member.saving_book.total_compulsory_savings 
        @first_voluntary_savings = @member.saving_book.total_extra_savings
        puts "total extra savings: #{@first_voluntary_savings}"
        
        @first_transaction.should be_valid 
        
        
        first_compulsory_diff = @first_compulsory_savings - @initial_compulsory_savings 
        first_compulsory_diff.should == BigDecimal("0")

        first_extra_diff = @first_voluntary_savings - @initial_voluntary_savings 
        first_extra_diff.should == @savings_amount 
        
        puts "First extra diff: #{first_extra_diff}"
        
        
      end
      
      it 'should create the first transaction and one member history' do
        @first_transaction.should be_valid 
         
        
         MemberPaymentHistory.where(
            :weekly_task_id    => @weekly_task.id,
            :member_id => @member.id , 
            :loan_product_id => @group_loan.id, 
            :loan_product_type => LOAN_PRODUCT[:group_loan]
          ).count == 1
          
          
        MemberPaymentHistory.where(
          :transaction_activity_id => @first_transaction.id 
        ).first.revision_code.should == REVISION_CODE[:original_only_savings] 
         
      end
      
      it "should create 2 history if only savings -> normal " do
        extra_savings = BigDecimal("1000")
        # initial extra savings = @savings_amount 
        initial_extra_savings = @savings_amount
        
        BacklogPayment.where(:member_id => @member.id ).count.should == 1 
        
        
        ActiveRecord::Base.transaction do
        @second_transaction = TransactionActivity.update_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @cash_payment + extra_savings,
          @savings_withdrawal, 
          @number_of_weeks,
          @number_of_backlogs   
        )
        end


        @second_transaction.should be_valid 
        @first_transaction.reload
        @first_transaction.is_deleted.should be_true 


        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan]
        ).count == 2 

        last_member_payment_history =  MemberPaymentHistory.where(
          :transaction_activity_id => @second_transaction.id 
        ).first 
        
        last_member_payment_history.revision_code == REVISION_CODE[:only_savings][:normal]
        
        BacklogPayment.where(:member_id => @member.id ).count.should == 0 
        
        # check the compulsory savings and voluntary savings
        # after first transaction, initial compulsory savings is intact
        #                           extra savings  => increased by (initial_extra_savings)
        # after first change, diff in extra savings => -intial_extra_savings + extra_savings 
        # =>                  diff in compulsory savings => + 1 week of compulsory savings 
        
        @member.reload 
        second_compulsory_savings_diff = @member.saving_book.total_compulsory_savings - @initial_compulsory_savings 
        second_voluntary_savings_diff = @member.saving_book.total_extra_savings - @initial_voluntary_savings 
        
         
        
        second_compulsory_savings_diff.should == @first_glm.group_loan_product.min_savings 
        second_voluntary_savings_diff.should ==  extra_savings
      end
      
      it 'should create 2 history if only savings -> only savings' do
        extra_savings = BigDecimal("1000") 
        initial_extra_savings = @savings_amount
        
        ActiveRecord::Base.transaction do
        @second_transaction =  TransactionActivity.update_savings_only_weekly_payment(
          @member,
          @weekly_task,
          extra_savings,
          @field_worker 
        )
        end


        @second_transaction.should be_valid 
        @first_transaction.reload
        @first_transaction.is_deleted.should be_true 


        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan]
        ).count == 2 

        last_member_payment_history =  MemberPaymentHistory.where(
          :transaction_activity_id => @second_transaction.id 
        ).first 
        last_member_payment_history.revision_code == REVISION_CODE[:only_savings][:only_savings]
        
        @member.reload 
        second_compulsory_savings_diff = @member.saving_book.total_compulsory_savings - @initial_compulsory_savings 
        second_voluntary_savings_diff = @member.saving_book.total_extra_savings - @initial_voluntary_savings 
        
        puts "666 second voluntary savings: #{@member.saving_book.total_extra_savings }" 
         puts "666 initial voluntary savings: #{@initial_voluntary_savings }" 
        
        second_compulsory_savings_diff.should == BigDecimal('0')
        second_voluntary_savings_diff.should ==  extra_savings
      end
      
      it 'should create 2 history if only savings -> no payment' do 
        @member_payment = @weekly_task.update_weekly_payment_declared_as_no_payment(@field_worker , @member)  
        
        @member_payment.no_payment?.should be_true 
         
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan] 
        ).count == 2
        
        
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan],
          :revision_code =>  REVISION_CODE[:only_savings][:no_payment] 
        ).count == 1
        
        @first_transaction.reload
        @first_transaction.is_deleted.should be_true 
        
        @member.reload 
        second_compulsory_savings_diff = @member.saving_book.total_compulsory_savings - @initial_compulsory_savings 
        second_voluntary_savings_diff = @member.saving_book.total_extra_savings - @initial_voluntary_savings 
        
        puts "666 second voluntary savings: #{@member.saving_book.total_extra_savings }" 
         puts "666 initial voluntary savings: #{@initial_voluntary_savings }" 
        
        second_compulsory_savings_diff.should == BigDecimal('0')
        second_voluntary_savings_diff.should ==  @initial_voluntary_savings 
        # the extra savings is removed. hence no more savings
        
        BacklogPayment.where(:member_id => @member.id, :is_cleared => false ).count.should == 1 
      end
    end # end of start with only savings 
    
    
    
    
    context "start with no payment " do 
      before(:each) do 
        @weekly_task = @group_loan.weekly_tasks.first  
        
        @first_glm = @group_loan.active_group_loan_memberships[0] 
          
        @member =  @first_glm.member  

        
         
       @weekly_task.mark_attendance_as_present( @first_glm.member, @field_worker )
        # do payment 
        @weekly_task = @group_loan.currently_executed_weekly_task
        @glp = @first_glm.group_loan_product
         
        @cash_payment = @glp.total_weekly_payment
        @savings_withdrawal = BigDecimal("0")
        @number_of_weeks = 1 
        @number_of_backlogs = 0 
        
        @savings_amount = @cash_payment * 0.5   
        
        @initial_compulsory_savings = @member.saving_book.total_compulsory_savings 
        @initial_voluntary_savings = @member.saving_book.total_extra_savings
        
        @first_member_payment = @weekly_task.create_weekly_payment_declared_as_no_payment(@field_worker , @member)  
        @first_member_payment.no_payment?.should be_true 
         
        
        @initial_compulsory_savings.should == @glp.initial_savings 
        @initial_voluntary_savings.should == BigDecimal('0')
        
        
      end
      
      it 'should create the first transaction and one member history' do
         
        
         MemberPaymentHistory.where(
            :weekly_task_id    => @weekly_task.id,
            :member_id => @member.id , 
            :loan_product_id => @group_loan.id, 
            :loan_product_type => LOAN_PRODUCT[:group_loan]
          ).count == 1
          
        MemberPaymentHistory.where(
            :weekly_task_id    => @weekly_task.id,
            :member_id => @member.id , 
            :loan_product_id => @group_loan.id, 
            :loan_product_type => LOAN_PRODUCT[:group_loan]
          ).first.revision_code.should == REVISION_CODE[:original_no_payment] 
           
         
      end
      
      it "should create 2 history if no payment -> normal " do
        BacklogPayment.where(:member_id => @member.id, :is_cleared => false ).count.should ==1 
        
        extra_savings =  BigDecimal('1000')
        ActiveRecord::Base.transaction do
        @second_transaction = TransactionActivity.update_generic_weekly_payment(
          @weekly_task, 
          @first_glm,
          @field_worker,
          @cash_payment + extra_savings,
          @savings_withdrawal, 
          @number_of_weeks,
          @number_of_backlogs   
        )
        end
      
      
        @second_transaction.should be_valid  
        @member_payment = @weekly_task.member_payment_for(@member)  
        
        @member_payment.is_full_payment?.should be_true 
      
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan]
        ).count == 2 
      
        last_member_payment_history =  MemberPaymentHistory.where(
          :transaction_activity_id => @second_transaction.id 
        ).first 
        
        last_member_payment_history.revision_code == REVISION_CODE[:no_payment][:normal]
        
        BacklogPayment.where(:member_id => @member.id, :is_cleared => false ).count.should == 0 
        
        @member.reload 
        # check extra savings 
        final_compulsory_savings = @member.saving_book.total_compulsory_savings 
        final_voluntary_savings = @member.saving_book.total_extra_savings 
        
        compulsory_savings_diff = final_compulsory_savings - @initial_compulsory_savings
        voluntary_savings_diff = final_voluntary_savings - @initial_voluntary_savings 
        
        compulsory_savings_diff.should == @glp.min_savings 
        voluntary_savings_diff.should == extra_savings 
        
        
        
      end
      
      it 'should create 2 history if no payment -> only savings' do
        extra_savings = BigDecimal("10000")
        
        BacklogPayment.where(:member_id => @member.id).count == 1 
        ActiveRecord::Base.transaction do
        @second_transaction =  TransactionActivity.update_savings_only_weekly_payment(
          @member,
          @weekly_task,
          extra_savings,
          @field_worker 
        )
        end
      
      
        @second_transaction.should be_valid 
       
      
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan]
        ).count == 2 
      
        last_member_payment_history =  MemberPaymentHistory.where(
          :transaction_activity_id => @second_transaction.id 
        ).first 
        last_member_payment_history.revision_code == REVISION_CODE[:no_payment][:only_savings]
        
        BacklogPayment.where(:member_id => @member.id).count == 1 
        @member.reload 
        # check extra savings 
        final_compulsory_savings = @member.saving_book.total_compulsory_savings 
        final_voluntary_savings = @member.saving_book.total_extra_savings 
        
        compulsory_savings_diff = final_compulsory_savings - @initial_compulsory_savings
        voluntary_savings_diff = final_voluntary_savings - @initial_voluntary_savings 
        
        compulsory_savings_diff.should == BigDecimal('0')
        voluntary_savings_diff.should == extra_savings
        
        
      end
      
      it 'should create 2 history if no payment -> no payment' do 
        @member_payment = @weekly_task.update_weekly_payment_declared_as_no_payment(@field_worker , @member)  
        
        @member_payment.should be_nil
                 
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan] 
        ).count == 1
        
        
        MemberPaymentHistory.where(
          :weekly_task_id    => @weekly_task.id,
          :member_id => @member.id , 
          :loan_product_id => @group_loan.id, 
          :loan_product_type => LOAN_PRODUCT[:group_loan],
          :revision_code =>  REVISION_CODE[:original_no_payment] 
        ).count == 1
         
      end
    end # end of start no payment


  end



end
     