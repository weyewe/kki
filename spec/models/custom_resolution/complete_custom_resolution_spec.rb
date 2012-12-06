require 'spec_helper'

describe GroupLoan do
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
      GroupLoanSubcription.create_or_change( @group_loan_product_a.id  ,  glm.id  )
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
  
  context "testing the post conditions" do
    it "should have 7 active members" do 
      @group_loan.active_group_loan_memberships.count.should == 7 
    end
    
    it "should have 9 members attending teh financial education" do
      @group_loan.membership_attending_financial_education.count.should == 9
    end
    
    it "should have 7 members attending the loan disbursement" do
      @group_loan.membership_attending_financial_education.count.should == 9
    end
    
    it "should return the loan disbursement of 2 members" do 
      @group_loan.membership_whose_loan_disbursement_must_be_returned_to_cashier.count.should == 2 
      
      total_disbursement_returned = BigDecimal("0")
      @group_loan.membership_whose_loan_disbursement_must_be_returned_to_cashier.each do |glm|
        glp = glm.group_loan_product
        total_disbursement_returned += glp.loan_amount - glp.setup_payment_amount
      end
      total_disbursement_returned.should == @group_loan.total_amount_to_be_returned_to_cashier
    end
    
    
    
    
  end # end of "testing the post conditions"  context 
  
  context "Preparing custom payment" do 
    before(:each) do
      @defaultee_glm_list = @first_sub_group.active_group_loan_memberships[0..1] + @second_sub_group.active_group_loan_memberships[0..1]
      @defaultee_glm_id_list = @defaultee_glm_list.collect {|x| x.id }
      puts "the list: #{@defaultee_glm_id_list}"
      
      # now we have 4.. each of them only pay once for weekly payment
      
      
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          
          # present in the weekly meeting. declaring no payment 
          if @defaultee_glm_id_list.include?(glm.id)  and #   and [1,2,3].include?(weekly_task.week_number)
              weekly_task.week_number == @group_loan.weekly_tasks.count 
            weekly_task.mark_attendance_as_present( glm.member, @field_worker )
            weekly_task.create_weekly_payment_declared_as_no_payment(@field_worker,  glm.member )
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
                  number_of_backlogs,
                  false
          )
          
          a.should be_valid 
          
      
          
          
          saving_book.reload
          
          final_total_savings      = saving_book.total 
          final_extra_savings      = saving_book.total_extra_savings
          final_compulsory_savings = saving_book.total_compulsory_savings
          diff = final_total_savings - initial_total_savings
          diff_extra_savings = final_extra_savings - initial_extra_savings
          diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
          
          
          puts "final compulsory_savings: #{final_compulsory_savings}"
          puts "\n******THE ANALYTICS"
          puts "glp min_savings : #{glp.min_savings}"
          puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
          puts "diff extra_savings: #{diff_extra_savings.to_i}"
          puts "The amount of diff for member #{member.id}: #{diff}"
          
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
    end
    
    it 'should produces 4xnumber of weeks unpaid grace period' do
      @defaultee_glm_list.each do |glm|
        glm.reload
        glm.unpaid_backlogs.count.should ==  1 
      end
    end
    
    it 'should not be able to do group loan closing' do
      closing_result = @group_loan.close_group_loan(@branch_manager)
      closing_result.should be_nil
    end
    
    it 'should produce enough compulsory savings' do
      puts '#############################################'
      puts '#############################################'
      puts '#############################################'
      
      
      puts "Total unpaid grace period amount: #{@group_loan.unpaid_grace_period_amount.to_i}"
      sum = BigDecimal('0')
      @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
        glp = glm.group_loan_product
        
        puts "glm #{glm.id}'s total compulsory savings : #{glm.member.saving_book.total_compulsory_savings.to_i}"
        sum += glm.member.saving_book.total_compulsory_savings
      end
      
      puts "Total available compulsory savings: #{sum.to_i}"
    end
    
    
    # we should make the glm - custom amount 
    context 'creating custom payment' do
      
      # Total unpaid grace period amount: 112000
      # glm 1652's total compulsory savings : 35000
      # glm 1653's total compulsory savings : 35000
      # glm 1654's total compulsory savings : 35000
      # glm 1655's total compulsory savings : 35000
      # glm 1656's total compulsory savings : 40000
      # glm 1657's total compulsory savings : 40000
      # glm 1658's total compulsory savings : 40000
      
      # only payable using compulsory savings... how ? 
      it 'should allow custom proposal if the amount if just right'  do
        payment = [
          BigDecimal('20000'),
          BigDecimal('20000'),
          BigDecimal('10000'),  # 50000
          BigDecimal('20000'), # 70000
          BigDecimal("20000"), # 90000
          BigDecimal("10000"), #100,000
          BigDecimal('12000')  # 112,000
        ]
        @glm_payment_pair_list = []
        count = 0
        
        @group_loan.active_group_loan_memberships.order('created_at ASC').each do |glm | 
          @glm_payment_pair_list << {
           :glm_id =>  glm.id,
           :amount => payment[count]
          } 
          count +=1 
        end
        
        @group_loan.propose_custom_default_payment_execution(@field_worker, @glm_payment_pair_list) 
        
        @group_loan.is_default_payment_resolution_proposed.should be_true 
        @group_loan.is_custom_default_payment_resolution.should be_true  
      end
      
      
      it 'should not allow custom proposal total custom amount > total unpaid' do
        payment = [
          BigDecimal('20000'),
          BigDecimal('20000'),
          BigDecimal('10000'),  # 50000
          BigDecimal('20000'), # 70000
          BigDecimal("20000"), # 90000
          BigDecimal("10000"), #100,000
          BigDecimal('20000')  # 120,000
        ]
        @glm_payment_pair_list = []
        count = 0
        
        @group_loan.active_group_loan_memberships.order('created_at ASC').each do |glm | 
          @glm_payment_pair_list << {
           :glm_id =>  glm.id,
           :amount => payment[count]
          } 
          count +=1 
        end
        
        @group_loan.propose_custom_default_payment_execution(@field_worker, @glm_payment_pair_list) 
        
        @group_loan.is_default_payment_resolution_proposed.should be_false 
        @group_loan.is_custom_default_payment_resolution.should be_false
      end
      
      it 'should not allow custom proposal total custom amount < total unpaid' do
        payment = [
          BigDecimal('20000'),
          BigDecimal('20000'),
          BigDecimal('10000'),  # 50000
          BigDecimal('20000'), # 70000
          BigDecimal("20000"), # 90000
          BigDecimal("10000"), #100,000
          BigDecimal('10000')  # 110,000
        ]
        @glm_payment_pair_list = []
        count = 0
        
        @group_loan.active_group_loan_memberships.order('created_at ASC').each do |glm | 
          @glm_payment_pair_list << {
           :glm_id =>  glm.id,
           :amount => payment[count]
          } 
          count +=1 
        end
        
        @group_loan.propose_custom_default_payment_execution(@field_worker, @glm_payment_pair_list) 
        
        @group_loan.is_default_payment_resolution_proposed.should be_false 
        @group_loan.is_custom_default_payment_resolution.should be_false
      end
    end
   
     
    context 'custom payment post condition' do
      before(:each) do
        @payment = [
          BigDecimal('20000'),
          BigDecimal('20000'),
          BigDecimal('10000'),  # 50000
          BigDecimal('20000'), # 70000
          BigDecimal("20000"), # 90000
          BigDecimal("10000"), #100,000
          BigDecimal('12000')  # 112,000
        ]
        @glm_payment_pair_list = []
        count = 0
        @initial_compulsory_savings_list = []
        @group_loan.active_group_loan_memberships.order('created_at ASC').each do |glm | 
          @glm_payment_pair_list << {
           :glm_id =>  glm.id,
           :amount => @payment[count]
          } 
          
          @initial_compulsory_savings_list << glm.member.saving_book.total_compulsory_savings 
          count +=1 
        end
        
        @group_loan.propose_custom_default_payment_execution(@field_worker, @glm_payment_pair_list) 
      end
      
      it 'should have updated the custom amount on the default payment' do
        count = 0 
        @group_loan.active_group_loan_memberships.order('created_at ASC').each do |glm |  
          default_payment = glm.default_payment 
          default_payment.custom_amount.should == @payment[count]
          count += 1 
        end
      end 
      
      context 'post confirmation by cashier' do
        before(:each) do  
          @group_loan.execute_default_payment_execution( @cashier ) 
        end
        
        
        it 'should have been default_payment executed' do
          @group_loan.is_default_payment_resolution_approved.should be_true 
        end
        
        it 'should produces the right number of transaction activities, with transaction-case: custom default payment resolution' do
          TransactionActivity.where(
            :transaction_case => TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_custom_amount] ,
            :loan_type => LOAN_TYPE[:group_loan] , 
            :loan_id => @group_loan.id ,
            :is_approved => true  
          ).count.should == @group_loan.active_group_loan_memberships.count 
        end
        
        it 'should mark all default payment as paid' do
          @group_loan.active_group_loan_memberships.each do |glm|
            default_payment = glm.default_payment
            default_payment.is_paid.should be_true 
          end
        end
        
        it "should deduct the member's compulsory savings by the custom amount " do
          count = 0 
          @group_loan.reload
          @group_loan.active_group_loan_memberships.order("created_at ASC"). each do |glm|
            delta =  @initial_compulsory_savings_list[count]  -  glm.member.saving_book.total_compulsory_savings
            delta.should == @payment[count]
            count += 1 
          end
        end 
      end
    end
    
    
    
    
    
    
   
  end
end