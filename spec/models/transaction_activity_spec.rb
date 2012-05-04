require 'spec_helper'

describe TransactionActivity do 
  before(:each) do 
    
    # how to prevent  double factories creation?
    # now , we are using the basic shite -> find it in db. if exists, use the one in DB
    # is there something like  FactoryGirl.find_or_create(:factory_name) << find this out. 
    # Will solve the problem in beautiful manner
    
    
    # what am I worried about? 
    # double factory creation => in creating the office, we triggered :
    # =>    1. Regency (North Jakarta)
          # triggered jakarta_province
    # =>    2. Subdistrict (Cilincing) 
          # triggered north jakarta regency
    # by now, if we did something wrong, we will have: 2 north_jakarta_regency, 2 provinces, 2 islands 
    
    # in the group_loan_commune creation, we triggered:
    # =>  1. Village (Kalibaru)
          # kalibaru villages triggered Cilincing subdistrict
          # Cilincing subdistrict triggerd north jakarta regency
          # and so on
    # by now we have 1 kalibaru_village, 2 cilincing subdistricts
    #  3 north jakarta regencies, 3 provinces, 3 islands
    
    # FUCK
    
    # we need branch manager  DONE
    # we need loan officer   DONE
    # we need cashier   DONE 
    # we need field_worker   DONE 
    # we need group_loan  DONE
    
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
    
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
            :commune_id => @group_loan_commune }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id )
    # we need these members hooked to the group loan (group_loan_memberships)
    @members.each do |member|
      GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
    end
    
    # we need group_loan_product x 3 , just for variations
    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)
    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)
    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)
    
    #assign the group_loan_product subcription 
    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
    @members.each do |member|
       # randomized
      glm = GroupLoanMembership.find(:first, :conditions => {
        :member_id => member.id,
        :group_loan_id => @group_loan.id 
      })
      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
    end
    
    #start the group loan (the approval cycle)
    @group_loan.execute_propose_finalization( @loan_officer )
    @group_loan.start_group_loan( @branch_manager )
    
    puts "At the end of the highest before block"
    
    puts "total villages : #{Village.count}"
    puts "total subdistricts: #{Subdistrict.count}"
    puts "total regencies: #{Regency.count}"
    puts "total provinces: #{Province.count}"
    puts "total island: #{Island.count}"
  end
  
  
  context "add independent_savings_deposit " do
    before(:each) do 
      @member = @members[rand(8)]
    end
    it "should not receive negative  or 0 amount" do
      savings_amount = BigDecimal("-50000")
      transaction_activity = TransactionActivity.create_independent_savings( @member, savings_amount, @field_worker )
      transaction_activity.should be_nil
      
      savings_amount = BigDecimal("0")
      transaction_activity = TransactionActivity.create_independent_savings( @member, savings_amount, @field_worker )
      transaction_activity.should be_nil
      
      
      savings_amount = BigDecimal("50000")
      transaction_activity = TransactionActivity.create_independent_savings( @member, savings_amount, @field_worker )
      
      transaction_activity.should be_valid
    end
    
    it "will add member savings, create 1 transaction entry in the process" do
      total_initial_savings = @member.total_savings
      savings_amount = BigDecimal("50000")
      transaction_activity = TransactionActivity.create_independent_savings( @member, savings_amount, @field_worker )
      
      
      total_final_savings = @member.total_savings
      (total_final_savings - total_initial_savings).should == savings_amount
      
      transaction_activity.should have(1).transaction_entries
      
      independent_savings_deposit  = transaction_activity.transaction_entries.first 
      independent_savings_deposit.transaction_entry_code.should == TRANSACTION_ENTRY_CODE[:independent_savings_deposit]
    end
    
    it "has to be done by a cashier of the same office where the member is registered" 
    # we don't know anything about this rule yet 
  end
  
  
  context "Setup Payment Transaction Activity" do 
    it "is paid by deducting the loan"
    it "can be in cash without loan deduction"
    it "can by paid without loan deduction, but the savings withdrawal can't exceed the member's total savings"
    # is there special rule applied with member's total_savings?
    it "is marked as the setup payment transaction "
  end
  
  context "Loan Disbursement Transaction Activity: group loan has been approved and 
            setup payment has been taken" do
    
    # clear the setup payment transaction( everyone decides to do setup payment using the loan)
    before(:each) do 
      @members.each do |member|
        glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
        })
        glm.declare_setup_payment_by_loan_deduction
      end
      
      @group_loan.execute_finalize_setup_fee_collection( @field_worker )
      @group_loan.approve_setup_fee_collection( @cashier )
    end

    
    it "will execute loan disbursement if the current_user role is cashier" do 
       member = @members[ rand(8) ]
       glm = GroupLoanMembership.find(:first, :conditions => {
         :member_id => member.id,
         :group_loan_id => @group_loan.id 
       })
       
       [@cashier, @field_worker, @branch_manager, @loan_officer].each do |employee|
         transaction = TransactionActivity.execute_loan_disbursement( glm , employee )
         if employee.has_role?(:cashier, employee.get_active_job_attachment)   
           transaction.should be_valid
         else
           transaction.should be_nil  #equal(nil)
         end
       end
     end
    
    it "will return the transaction_activity if it has been executed previously" do 
      member = @members[ rand(8) ]
      glm = GroupLoanMembership.find(:first, :conditions => {
        :member_id => member.id,
        :group_loan_id => @group_loan.id 
      })
      
      
      transaction_1 = TransactionActivity.execute_loan_disbursement( glm , @cashier )
      transaction_1.should be_valid
      
      transaction_2 = TransactionActivity.execute_loan_disbursement( glm , @cashier  )
      transaction_2.id.should  == transaction_1.id
    end
    
    context "post condition after the disbursement transaction activity (deduct loan amount case)" do
      before(:each) do 
        member = @members[ rand(8) ]
        @glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
          })

        @transaction_1_executed = TransactionActivity.execute_loan_disbursement( @glm , @cashier )
      end

      it "will deduct the disbursement amount if the deposit is done by 'loan deduction scheme'" do
        group_loan_product = @glm.group_loan_product 
        full_loan_amount  = group_loan_product.loan_amount
        setup_fee = group_loan_product.setup_payment_amount
      
        total_money_received_by_member = full_loan_amount - setup_fee
      
      # difference between equal and == 
      # equal is checking the object identity
      # == is checking the magnitude 
        puts "actual value is #{@transaction_1_executed.total_transaction_amount}"
        puts "expected value is #{total_money_received_by_member}"
        @transaction_1_executed.total_transaction_amount.should  ==  total_money_received_by_member 
      end

      it "will create 2 transaction entries: giving the full amount to the member, 
          and the member will return the one equal with setup amount " do
        @transaction_1_executed.transaction_case.should ==TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction]             
        @transaction_1_executed.should have(2).transaction_entries 
      
      
        group_loan_product = @glm.group_loan_product 
        full_loan_amount  = group_loan_product.loan_amount
        setup_fee = group_loan_product.setup_payment_amount
      
        total_money_exchanging_hands = full_loan_amount - setup_fee
        
        
        # check the transaction entries case 
        deducted_loan_disbursement_count = 0 
        deduction_of_loan_disbursement_count = 0
        amount_of_deducted_loan_disbursement = BigDecimal("0")
        amount_of_loan_disbursement_deduction = BigDecimal('0')
        @transaction_1_executed.transaction_entries.each do  |t_entry|
          if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:total_loan_disbursement_amount]
            deducted_loan_disbursement_count += 1 
            ( total_money_exchanging_hands + setup_fee).should == t_entry.amount
          end
          if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:setup_fee_deduction_from_disbursement_amount]
            deduction_of_loan_disbursement_count += 1 
            setup_fee.should == t_entry.amount
          end
        end
      
        deducted_loan_disbursement_count.should ==  1 
        deduction_of_loan_disbursement_count.should  == 1 
        @transaction_1_executed.total_transaction_amount.should  ==  total_money_exchanging_hands 
      end  # end of the it block
      
      
      it "will not increase member's savings. no effects"
    end # end of post loan_disbursement transaction  context
    
    context "cashier approval can be done if all members have received the loan disbursement" do
      it "will produce false approval if not all members has received the loan disbursement" do
        # total members == 8 
        @group_loan.group_loan_memberships[0..5].each do |glm|
          TransactionActivity.execute_loan_disbursement( glm , @cashier )
        end
        
        @group_loan.execute_finalize_loan_disbursement( @cashier ).should be_false 
      end
      
      it "will produce false approval if not all members has received the loan disbursement" do
        @group_loan.group_loan_memberships.each do |glm|
          TransactionActivity.execute_loan_disbursement( glm , @cashier )
        end

        @group_loan.execute_finalize_loan_disbursement( @cashier ).should be_true
      end
    end #end of cashier approval context 
  end # end of loan_disbursement context
  
  describe "Weekly Loan Payment Transaction Activity" do 
    before(:each) do
      @members.each do |member|
        glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
        })
        glm.declare_setup_payment_by_loan_deduction
      end
      
      @group_loan.execute_finalize_setup_fee_collection( @field_worker )
      @group_loan.approve_setup_fee_collection( @cashier )
      
      # create loan disbursement
      @group_loan.group_loan_memberships.each do |glm|
        TransactionActivity.execute_loan_disbursement( glm , @cashier )
      end
      #finalize loan disbursement 
      @group_loan.execute_finalize_loan_disbursement( @cashier )
    end
    
    context "all payments behavior" do
      it "should have equal number of weekly_tasks in group_loan.total_weeks" do
        puts "Total weeks == #{@group_loan.total_weeks}"
        @group_loan.should have(@group_loan.total_weeks).weekly_tasks
      end
      
      it "should have completed the weekly_task, meeting part before proceeding to weekly payment, any kind of payments" do
        # we don't need to enforce this rule.. if they have the money, they can do the structured multiple weeks payment
      end
    end
    
    context "basic payment" do
      
      it "can only be paid if the weekly meeting has been finalized" do
        member = @members[rand(8)]
        weekly_task = @group_loan.currently_executed_weekly_task 
        puts "#{weekly_task.week_number}" 
        
        basic_weekly_payment  = TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
        basic_weekly_payment.should be_nil
      end
      
      it "can only be paid if the executor has role field_worker and the weekly meeting is finalized" do
        weekly_task = @group_loan.currently_executed_weekly_task 
      
        # marking all the attendances, collection of present, absent , late 
        @members.each do |member|
          value = rand(3)
          if value == 0
            weekly_task.mark_attendance_as_late(member, @field_worker )
          elsif value ==1 
            weekly_task.mark_attendance_as_present(member, @field_worker  )
          elsif value == 2 
            weekly_task.mark_attendance_as_absent(member, @field_worker  )
          end
        end
        
        member = @members[rand(8)]
        basic_weekly_payment  = TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
        basic_weekly_payment.should be_nil
        
        weekly_task.close_weekly_meeting( @field_worker )
        basic_weekly_payment  = TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
        basic_weekly_payment.should be_valid
      end
      
      context "post-transaction conditions for basic payment" do
        before(:each) do 
          @weekly_task_for_basic_payment = @group_loan.currently_executed_weekly_task 

          # marking all the attendances, collection of present, absent , late 
          @members.each do |member|
            value = rand(3)
            if value == 0
              @weekly_task_for_basic_payment.mark_attendance_as_late(member, @field_worker )
            elsif value ==1 
              @weekly_task_for_basic_payment.mark_attendance_as_present(member, @field_worker  )
            elsif value == 2 
              @weekly_task_for_basic_payment.mark_attendance_as_absent(member, @field_worker  )
            end
          end
          @weekly_task_for_basic_payment.close_weekly_meeting( @field_worker )
          @member_for_basic_payment = @members[rand(8)]
          @total_savings_before_transaction = @member_for_basic_payment.total_savings
          @total_saving_entries_count_before_basic_payment = @member_for_basic_payment.saving_book.saving_entries.count 
          @basic_weekly_payment_transaction  = TransactionActivity.create_basic_weekly_payment(@member_for_basic_payment,
                                @weekly_task_for_basic_payment, 
                                @field_worker )
        end
        
        it "will produce total transaction amount equals basic weekly payment of the group loan product " do
          glm = @group_loan.group_loan_memberships.where(:member_id => @member_for_basic_payment.id ).first
          group_loan_product = glm.group_loan_product
          @basic_weekly_payment_transaction.total_transaction_amount.should == group_loan_product.total_weekly_payment
        end
        
        it "will have transaction_case:#{TRANSACTION_CASE[:weekly_payment_basic]} " do
          @basic_weekly_payment_transaction.transaction_case.should == TRANSACTION_CASE[:weekly_payment_basic]
        end
        it "won't create double basic_weekly_payment for the same week" do
          another_weekly_payment = TransactionActivity.create_basic_weekly_payment(@member_for_basic_payment,
                                @weekly_task_for_basic_payment, 
                                @field_worker )
                                
          another_weekly_payment.id.should  == @basic_weekly_payment_transaction.id
        end
        
        context "checking the transaction entries generated" do
          before(:each) do
            @principal_count = 0
            @interest_count = 0
            @savings_count = 0 
            @weekly_saving_transaction_entry  = ''
            @weekly_principal_transaction_entry = ''
            @weekly_interest_transaction_entry =''
            @basic_weekly_payment_transaction.transaction_entries.each do |te|
              if te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_principal]
                @principal_count += 1 
                @weekly_saving_transaction_entry = te
              elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_saving]
                @savings_count += 1
                @weekly_saving_transaction_entry = te
              elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_interest]
                @interest_count += 1 
                @weekly_interest_transaction_entry = te 
              end
            end
          end # end of the before block, in the "checking the transaction entries generated context"
          
          it 'will create 3 transaction entries: principal, interest and savings' do
            @basic_weekly_payment_transaction.should have(3).transaction_entries
            @principal_count.should == 1 
            @savings_count.should == 1 
            @interest_count.should == 1 
            @weekly_saving_transaction_entry.should be_valid
            @weekly_saving_transaction_entry.should be_valid
            @weekly_interest_transaction_entry.should be_valid
          end

          it "produces one extra saving_entry for the member, with value equal to the min_savings" do
            # @total_saving_entries_count_before_basic_payment
            total_saving_entries_count_after_basic_payment = @member_for_basic_payment.saving_book.saving_entries.count
            (total_saving_entries_count_after_basic_payment - @total_saving_entries_count_before_basic_payment).should == 1 

            saving_entry = @member_for_basic_payment.saving_book.saving_entries.first
            puts "the amount is #{saving_entry.amount}  *****************"
          end

          it "produces link between saving_entry and the transaction_entry itself" do
            saving_entry = @member_for_basic_payment.saving_book.saving_entries.first

            saving_entry.transaction_entry_id.should_not be_nil
            saving_transaction_entry = saving_entry.transaction_entry 
            saving_transaction_entry.should_not be_nil
            @weekly_saving_transaction_entry.id.should_not be_nil
            @weekly_saving_transaction_entry.id.should  == saving_entry.transaction_entry_id 

          end

          it "the difference of member's total_savings is equal to the min_savings in the group loan product"  do
            glm = @group_loan.group_loan_memberships.where(:member_id => @member_for_basic_payment.id ).first
            group_loan_product = glm.group_loan_product

            puts "total savings before transaction = #{@total_savings_before_transaction }"
            puts "total savings after transaction = #{@member_for_basic_payment.total_savings}"
            puts "min savings in the group loan product = #{group_loan_product.min_savings}"
            total_savings_difference = @member_for_basic_payment.total_savings - @total_savings_before_transaction 
            total_savings_difference.should == group_loan_product.min_savings
          end
          
        end # end of context "checking the transaction entries generated"
      end # end of context "post-transaction conditions for basic payment"
      
      
    end #end of context "basic payment"
    
    context "special payment" do
      context "savings only" do
     
        it "can only be paid if the weekly meeting has been finalized" do
          member = @members[rand(8)]
          weekly_task = @group_loan.currently_executed_weekly_task
          savings_amount = BigDecimal("5000")
          savings_only_transaction = TransactionActivity.create_savings_only_weekly_payment(
                        member,
                        weekly_task,
                        savings_amount,
                        @field_worker)
                    
          savings_only_transaction.should be_nil
        end
        
       
        
        context "weekly meeting has been finalized" do
          before(:each) do
            @weekly_task = @group_loan.currently_executed_weekly_task
            @selected_member = @members[rand(8)]
            @members.each do |member|
              value = rand(3)
              if value == 0
                @weekly_task.mark_attendance_as_late(member, @field_worker )
              elsif value ==1 
                @weekly_task.mark_attendance_as_present(member, @field_worker  )
              elsif value == 2 
                @weekly_task.mark_attendance_as_absent(member, @field_worker  )
              end
            end

            @weekly_task.close_weekly_meeting( @field_worker )
          end
          
          it "can only be paid if the employee has role field_worker" do
            savings_amount = BigDecimal("5000")
            savings_only_transaction  = TransactionActivity.create_savings_only_weekly_payment(
                        @selected_member,
                        @weekly_task, 
                        savings_amount,
                        @cashier )
            savings_only_transaction.should be_nil
            
            savings_only_transaction  = TransactionActivity.create_savings_only_weekly_payment(
                        @selected_member,
                        @weekly_task, 
                        savings_amount,
                        @field_worker )
            savings_only_transaction.should be_valid
          end
          
          it "won't create double transaction_activity " do
            savings_amount = BigDecimal("5000")
            savings_only_transaction  = TransactionActivity.create_savings_only_weekly_payment(
                        @selected_member,
                        @weekly_task, 
                        savings_amount,
                        @field_worker )
            savings_only_transaction.should be_valid
            
            savings_only_transaction_2  = TransactionActivity.create_savings_only_weekly_payment(
                        @selected_member,
                        @weekly_task, 
                        savings_amount,
                        @field_worker )
            savings_only_transaction_2.id.should == savings_only_transaction.id
            
          end
          
          it "can only be paid if the savings_amount is bigger than 0" do
            savings_amount = BigDecimal("0")
            savings_only_transaction  = TransactionActivity.create_savings_only_weekly_payment(
                        @selected_member,
                        @weekly_task, 
                        savings_amount,
                        @field_worker )
                        
            savings_only_transaction.should be_nil
            
            savings_amount = BigDecimal("-500")
            savings_only_transaction  = TransactionActivity.create_savings_only_weekly_payment(
                        @selected_member,
                        @weekly_task, 
                        savings_amount,
                        @field_worker )
                        
            savings_only_transaction.should be_nil
            
            savings_amount = BigDecimal("5000")
            savings_only_transaction  = TransactionActivity.create_savings_only_weekly_payment(
                        @selected_member,
                        @weekly_task, 
                        savings_amount,
                        @field_worker )
                        
            savings_only_transaction.should be_valid
          end
          
          context "post transaction conditions: checking the transaction entries, savings, and backlog payment" do
            before(:each) do
              @total_member_savings_before_transaction = @selected_member.total_savings
              @savings_amount = BigDecimal("5000")
              @savings_only_transaction  = TransactionActivity.create_savings_only_weekly_payment(
                          @selected_member,
                          @weekly_task, 
                          @savings_amount,
                          @field_worker )
            end
            
            it "should produce 1 backlog payment"  do
              member_payment= @weekly_task.member_payment_for(@selected_member)
              member_payment.transaction_activity_id.should == @savings_only_transaction.id
              member_payment.backlog_payment.should be_valid
            end
            
            
            it "should produce only 1 transaction entry and the transaction_entry code is no weekly payment, just savings" do
              @savings_only_transaction.should have(1).transaction_entry 
              
              the_transaction_entry = @savings_only_transaction.transaction_entries.first 
              the_transaction_entry.transaction_entry_code.should == TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings]
            end
            
            it "should have linked transaction entry with the saving entry" do 
              the_saving_entry= @selected_member.saving_book.saving_entries.first 
              
              the_saving_entry.transaction_entry_id.should == @savings_only_transaction.transaction_entries.first.id
            end
            
            it "should add the total_savings by savings_amount" do
              total_savings_after_transaction = @selected_member.total_savings
              difference = total_savings_after_transaction - @total_member_savings_before_transaction 
              difference.should == @savings_amount
            end
          end
          
          
        end
        
        
      end # end of the savings only payment context 
      
      context "no payment declaration" do
        # general behavior 
        context "post transaction conditions"
        context "checking the transaction_entries generated and savings entries (side effect)"
        context "no double backlog_payment for the same weeks"
      end
      
      context "structured multiple weeks payment" do
        
        before(:each) do
          @selected_member = @members[rand(8)]
          @weekly_task = @group_loan.currently_executed_weekly_task
          @group_loan_product = @group_loan.group_loan_memberships.where(:member_id => @selected_member.id).first.group_loan_product
          # we need to finalize the weekly_meeting
          
          @members.each do |member|
            value = rand(3)
            if value == 0
              @weekly_task.mark_attendance_as_late(member, @field_worker )
            elsif value ==1 
              @weekly_task.mark_attendance_as_present(member, @field_worker  )
            elsif value == 2 
              @weekly_task.mark_attendance_as_absent(member, @field_worker  )
            end
          end
          @weekly_task.close_weekly_meeting( @field_worker )
        end
        # done in the context "Weekly Loan Payment Transaction Activity"
        # we have @members
        # we have @group_loan 
        # we have group_loan_memberships hooked in between the group_loan and the member
        # how about the group_loan_subcription? it is created as well
        # is the loan disbursed? yes
        # has cashier finalized it? yes 
         #now, it is just weekly rock and roll
        
        # TransactionActivity.create_structured_multiple_payment(
        #                      @member,
        #                      @weekly_task,
        #                      current_user,
        #                      cash,
        #                      savings_withdrawal,
        #                      number_of_weeks
        #                    )
        #    
        #    
        
        # general case
        # THESE ARE THE PRE CONDITIONS 
        it "should not accept negative value for cash" do
          cash = BigDecimal("-500")
          number_of_weeks = 1
          savings_withdrawal = BigDecimal("0")
          transaction_activity = TransactionActivity.create_structured_multiple_payment(
                       @selected_member,
                       @weekly_task,
                       @field_worker,
                       cash,
                       savings_withdrawal,
                       number_of_weeks
                     )
                     
          transaction_activity.should be_nil
        end
        
        it "should not accept negative value for savings withdrawal" do 
          cash = BigDecimal("5000")
          number_of_weeks = 1
          savings_withdrawal = BigDecimal("-500")
          transaction_activity = TransactionActivity.create_structured_multiple_payment(
                       @selected_member,
                       @weekly_task,
                       @field_worker,
                       cash,
                       savings_withdrawal,
                       number_of_weeks
                     )
                     
          transaction_activity.should be_nil
        end
        
        
        it "should not allow savings withdrawal bigger than 50% of total savings" do 
        # pending
        end
        
        
        it "should be inacceptable  if  1 <= number_of_weeks <= max_available" do
          # in total we have 5 
          cash = BigDecimal("500")
          number_of_weeks = 10 # in total, we have 5
          savings_withdrawal = BigDecimal("0")
          transaction_activity = TransactionActivity.create_structured_multiple_payment(
                       @selected_member,
                       @weekly_task,
                       @field_worker,
                       cash,
                       savings_withdrawal,
                       number_of_weeks
                     )
                     
          transaction_activity.should be_nil
          
          
          
          cash = BigDecimal("500")
          number_of_weeks = 0 # in total, we have 5
          savings_withdrawal = BigDecimal("0")
          transaction_activity = TransactionActivity.create_structured_multiple_payment(
                       @selected_member,
                       @weekly_task,
                       @field_worker,
                       cash,
                       savings_withdrawal,
                       number_of_weeks
                     )
                     
          transaction_activity.should be_nil
          
          selected_glm = GroupLoanMembership.find(:first, :conditions => {
            :member_id => @selected_member.id,
            :group_loan_id => @group_loan.id
          })
          
          group_loan_product = selected_glm.group_loan_product
          
          cash = group_loan_product.total_weekly_payment + BigDecimal("10000")
          number_of_weeks = 1 # in total, we have 5
          savings_withdrawal = BigDecimal("0")
          transaction_activity = TransactionActivity.create_structured_multiple_payment(
                       @selected_member,
                       @weekly_task,
                       @field_worker,
                       cash,
                       savings_withdrawal,
                       number_of_weeks
                     )
                     
          transaction_activity.should be_valid
        end
        
        
        # ACTUALLY, THIS IS THE POST CONDITIONS 
        context "weekly_payment_single_week_no_extra_savings " do 
          it "will just do basic_payment if no extra savings" do
            cash = @group_loan_product.total_weekly_payment
            savings_withdrawal = BigDecimal("0")
            number_of_weeks = 1
            # our loan duration = 5 weeks 
            transaction_activity = TransactionActivity.create_structured_multiple_payment(
                         @selected_member,
                         @weekly_task,
                         @field_worker,
                         cash,
                         savings_withdrawal,
                         number_of_weeks
                       )
                       
            transaction_activity.should be_valid
            transaction_activity.transaction_case.should == TRANSACTION_CASE[:weekly_payment_basic]
          end
          
          context "post conditions" do
            before(:each) do
              @initial_savings = @selected_member.total_savings

              cash = @group_loan_product.total_weekly_payment
              savings_withdrawal = BigDecimal("0")
              number_of_weeks = 1
              # our loan duration = 5 weeks 
              
              @initial_remaining_weekly_tasks_count = @group_loan.remaining_weekly_tasks_count_for_member(@selected_member)
              @initial_accounted_weekly_tasks = @group_loan.accounted_weekly_payments_by(@selected_member)
              @transaction_activity = TransactionActivity.create_structured_multiple_payment(
                           @selected_member,
                           @weekly_task,
                           @field_worker,
                           cash,
                           savings_withdrawal,
                           number_of_weeks
                         )
            end
            
            it "will increase the savings by min_savings" do
              final_savings = @selected_member.total_savings
              (final_savings-@initial_savings).should == @group_loan_product.min_savings
            end
            
            it "will create one member payment associated with the week's payment" do
              final_remaining_weekly_tasks_count = @group_loan.remaining_weekly_tasks_count_for_member(@selected_member)
              final_accounted_weekly_tasks  = @group_loan.accounted_weekly_payments_by(@selected_member)
              
              ( @initial_remaining_weekly_tasks_count -final_remaining_weekly_tasks_count ).should == 1 
              
              weekly_task = ( final_accounted_weekly_tasks - @initial_accounted_weekly_tasks ) .first
              member_payment = weekly_task.member_payment_for(@selected_member)
              member_payment.transaction_activity_id.should == @transaction_activity.id
            end
          end # end of context "post conditions"
          
        end # end of context "single week no extra savings"
        
        context "weekly_payment_single_week_extra_savings " do 
          # see how the payment works: conditions that triggers the payment 
          # see the post conditions 
          # the pre conditions for structured multiple payments is general
          
          context "post conditions"  do
            before(:each) do
              @initial_savings = @selected_member.total_savings 
              @extra_savings = BigDecimal("10000")
              cash = @group_loan_product.total_weekly_payment + @extra_savings
              savings_withdrawal = BigDecimal("0")
              number_of_weeks = 1
              # our loan duration = 5 weeks 
              
              @initial_remaining_weekly_tasks_count = @group_loan.remaining_weekly_tasks_count_for_member(@selected_member)
              @initial_accounted_weekly_tasks = @group_loan.accounted_weekly_payments_by(@selected_member)
              @transaction_activity = TransactionActivity.create_structured_multiple_payment(
                           @selected_member,
                           @weekly_task,
                           @field_worker,
                           cash,
                           savings_withdrawal,
                           number_of_weeks
                         )
            end
            
            it "should produce total transaction amount to be basic_weekly_payment + extra_savings " do
              @transaction_activity.total_transaction_amount.should == (@group_loan_product.total_weekly_payment + @extra_savings)
            end
            
            it "should produce total savings difference == min savings + extra savings"  do
              final_savings = @selected_member.total_savings
              (final_savings - @initial_savings).should == (@group_loan_product.min_savings  + @extra_savings)
            end
            
            it "should produce 4 transaction entries: principal, interest, min_savings, extra savings" do
              @transaction_activity.should have(4).transaction_entries
              
              min_saving_entry_count = 0
              principal_entry_count = 0 
              interest_entry_count = 0 
              extra_savings_entry_count = 0
              extra_savings_transaction_entry = ''
              
              @transaction_activity.transaction_entries.each do |te|
                if te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_principal]
                  principal_entry_count +=1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_saving]
                  min_saving_entry_count +=1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_interest]
                  interest_entry_count += 1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:extra_weekly_saving]
                  extra_savings_entry_count += 1 
                  extra_savings_transaction_entry = te
                end
              end
              
              min_saving_entry_count.should == 1 
              principal_entry_count.should == 1 
              interest_entry_count.should == 1 
              extra_savings_entry_count.should == 1 
              extra_savings_transaction_entry.amount.should == @extra_savings
           
            end
            
          end # end of context "post conditions"
        end # end of context "weekly_payment_single_week_extra_savings " 
        
        context "weekly_payment_single_week_structured_with_soft_savings_withdrawal"   do
          # there can be cash or no cash payment 
          
          # it "should not allow savings withdrawal with the amount > 50% total savings?"
          context "initial savings is less than the min payment" do
            it "should not allow the transaction if the total savings withdrawal + cash >  total savings" do
              # create savings, but less than the total weekly payment
              amount = 0.5 * @group_loan_product.total_weekly_payment
              TransactionActivity.create_independent_savings( @selected_member, amount, @field_worker )
              
              weekly_payment_transaction = TransactionActivity.create_structured_multiple_payment(
                    @selected_member, #member
                    @weekly_task,  # the weekly task
                    @field_worker, # the field worker 
                    BigDecimal("0"),   # the cash payment 
                    @group_loan_product.total_weekly_payment,  #savings withdrawal
                    1)# number of weeks
              weekly_payment_transaction.should be_nil
            end
            
            it "should allow the transaction if total_savings_withdrawal + cash >= total_savings, and create 4 transaction entries:
                    principal, interest, savings, savings_withdrawal" do
              savings_amount = 0.5 * @group_loan_product.total_weekly_payment
              TransactionActivity.create_independent_savings( @selected_member, savings_amount, @field_worker )
              
              cash_value = 0.5 * @group_loan_product.total_weekly_payment
              weekly_payment_transaction = TransactionActivity.create_structured_multiple_payment(
                    @selected_member, #member
                    @weekly_task,  # the weekly task
                    @field_worker, # the field worker 
                    cash_value,   # the cash payment 
                    savings_amount,  #savings withdrawal
                    1)# number of weeks
              weekly_payment_transaction.should be_valid
              weekly_payment_transaction.should have(4).transaction_entries
            end
            
            
          end
          
          context "there is initial savings, enough to pay the min weekly payment" do
            before(:each) do
              savings_amount = 2* @group_loan_product.total_weekly_payment
              TransactionActivity.create_independent_savings( @selected_member, savings_amount, @field_worker )
            end
            
            it "should create no extra savings if the ( savings withdrawal + cash ) == weekly payment" do
              weekly_payment_transaction = TransactionActivity.create_structured_multiple_payment(
                    @selected_member, #member
                    @weekly_task,  # the weekly task
                    @field_worker, # the field worker 
                    BigDecimal("0"),   # the cash payment 
                    @group_loan_product.total_weekly_payment,  #savings withdrawal
                    1)# number of weeks
              
              weekly_payment_transaction.should have(4).transaction_entries
              principal_transaction_entry_count  = 0
              savings_transaction_entry_count  = 0
              interest_transaction_entry_count  = 0
              savings_withdrawal_entry_count  = 0
              savings_withdrawal_transaction_entry = ''
              
              weekly_payment_transaction.transaction_entries.each do |te|
                if te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_principal]
                  principal_transaction_entry_count +=1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_saving]
                  savings_transaction_entry_count +=1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_interest]
                  interest_transaction_entry_count += 1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal]
                  savings_withdrawal_entry_count += 1 
                  savings_withdrawal_transaction_entry = te
                end
              end
              
              savings_transaction_entry_count.should == 1 
              principal_transaction_entry_count.should == 1 
              interest_transaction_entry_count.should == 1 
              savings_withdrawal_entry_count.should == 1 
              savings_withdrawal_transaction_entry.amount.should == @group_loan_product.total_weekly_payment
            end
            
            it "should create difference in total savings by extra savings - savings_withdrawal + min_savings" do
              
              initial_savings_amount = @selected_member.total_savings 
              cash_payment = BigDecimal("0")
              savings_withdrawal = @group_loan_product.total_weekly_payment
              number_of_weeks = 1
              weekly_payment_transaction = TransactionActivity.create_structured_multiple_payment(
                    @selected_member, #member
                    @weekly_task,  # the weekly task
                    @field_worker, # the field worker 
                    cash_payment,   # the cash payment 
                    savings_withdrawal,  #savings withdrawal
                    number_of_weeks)# number of weeks
              
              final_savings_amount = @selected_member.total_savings
              
              actual_total_savings_value = final_savings_amount - initial_savings_amount 
              expected_total_savings_value = cash_payment + ( @group_loan_product.min_savings * number_of_weeks)  - savings_withdrawal
              actual_total_savings_value.should == expected_total_savings_value
            end
            
            
          end #context :"there is initial savings, enough to pay for weekly payment"
          
        end
        
        context "weekly_payment_single_week_structured_with_soft_savings_withdrawal_extra_savings"  do
          before(:each) do
            savings_amount = 2* @group_loan_product.total_weekly_payment
            TransactionActivity.create_independent_savings( @selected_member, savings_amount, @field_worker )
          end
          
          it "should create 5 transaction entries if total_cash + total savings_withdrawal > weekly_payment" do
            # principal, savings, interest, savings_withdrawal, extra savings 
            cash_amount = BigDecimal("10000")
            savings_withdrawal_amount = @group_loan_product.total_weekly_payment
            weekly_payment_transaction = TransactionActivity.create_structured_multiple_payment(
                  @selected_member, #member
                  @weekly_task,  # the weekly task
                  @field_worker, # the field worker 
                  cash_amount,   # the cash payment 
                  savings_withdrawal_amount,  #savings withdrawal
                  1)# number of weeks
                  
            weekly_payment_transaction.should have(5).transaction_entries
            principal_transaction_entry_count  = 0
            savings_transaction_entry_count  = 0
            interest_transaction_entry_count  = 0
            savings_withdrawal_entry_count  = 0
            extra_savings_entry_count = 0 
            savings_withdrawal_transaction_entry = ''
            extra_savings_transaction_entry = ''

            weekly_payment_transaction.transaction_entries.each do |te|
              if te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_principal]
                principal_transaction_entry_count +=1 
              elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_saving]
                savings_transaction_entry_count +=1 
              elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_interest]
                interest_transaction_entry_count += 1 
              elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal]
                savings_withdrawal_entry_count += 1 
                savings_withdrawal_transaction_entry = te
              elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:extra_weekly_saving]
                extra_savings_entry_count += 1
                extra_savings_transaction_entry = te 
              end
            end

            savings_transaction_entry_count.should == 1 
            principal_transaction_entry_count.should == 1 
            interest_transaction_entry_count.should == 1 
            savings_withdrawal_entry_count.should == 1 
            extra_savings_entry_count.should == 1 
            savings_withdrawal_transaction_entry.amount.should == savings_withdrawal_amount
            expected_extra_savings = savings_withdrawal_amount + cash_amount  - @group_loan_product.total_weekly_payment
            extra_savings_transaction_entry.amount.should ==  expected_extra_savings
          end
          
          it "should create difference in total savings by extra savings - savings_withdrawal + min_savings" do
            initial_total_savings = @selected_member.total_savings
            cash_amount = BigDecimal("10000")
            savings_withdrawal_amount = @group_loan_product.total_weekly_payment
            number_of_weeks = 1 
            weekly_payment_transaction = TransactionActivity.create_structured_multiple_payment(
                  @selected_member, #member
                  @weekly_task,  # the weekly task
                  @field_worker, # the field worker 
                  cash_amount,   # the cash payment 
                  savings_withdrawal_amount,  #savings withdrawal
                  number_of_weeks)# number of weeks
            final_total_savings = @selected_member.total_savings
            
            actual_savings_difference = final_total_savings - initial_total_savings
            expected_savings_difference = cash_amount + (@group_loan_product.min_savings * number_of_weeks ) - savings_withdrawal_amount
            actual_savings_difference.should == expected_savings_difference
          end
          
        end #context "weekly_payment_single_week_structured_with_soft_savings_withdrawal_extra_savings"
        
        
        context "weekly_payment_structured_multiple_weeks" do
          before(:each) do
            savings_amount = 2* @group_loan_product.total_weekly_payment
            TransactionActivity.create_independent_savings( @selected_member, savings_amount, @field_worker )
            @number_of_weeks = 2
          end
          
          it "should not give transaction if (total_cash + savings_withdrawal) > number_of_weeks*weekly_payment" do
            cash_amount =  (@number_of_weeks - 0.5 )* @group_loan_product.total_weekly_payment  
            savings_withdrawal_amount  = BigDecimal("0")
            structured_transaction = TransactionActivity.create_structured_multiple_payment(
                  @selected_member, #member
                  @weekly_task,  # the weekly task
                  @field_worker, # the field worker 
                  cash_amount,   # the cash payment 
                  savings_withdrawal_amount,  #savings withdrawal
                  @number_of_weeks)# number of weeks
            
            structured_transaction.should be_nil 
          end
          
          context "post condition of multiple weeks , no extra savings, no savings withdrawal" do
            before(:each) do
              @cash_amount =  (@number_of_weeks )* @group_loan_product.total_weekly_payment  
              @savings_withdrawal_amount  = BigDecimal("0")
              @initial_total_savings = @selected_member.total_savings
              @structured_transaction = TransactionActivity.create_structured_multiple_payment(
                  @selected_member, #member
                  @weekly_task,  # the weekly task
                  @field_worker, # the field worker 
                  @cash_amount,   # the cash payment 
                  @savings_withdrawal_amount,  #savings withdrawal
                  @number_of_weeks)# number of weeks
            end
          
            it "should produce number_of_weeks*3 transaction_entries" do
              @structured_transaction.should have(@number_of_weeks*3).transaction_entries
              
              principal_transaction_entry_count  = 0
              savings_transaction_entry_count  = 0
              interest_transaction_entry_count  = 0
              
              @structured_transaction.transaction_entries.each do |te|
                if te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_principal]
                  principal_transaction_entry_count +=1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_saving]
                  savings_transaction_entry_count +=1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:weekly_interest]
                  interest_transaction_entry_count += 1 
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal]
                  savings_withdrawal_entry_count += 1 
                  savings_withdrawal_transaction_entry = te
                elsif te.transaction_entry_code == TRANSACTION_ENTRY_CODE[:extra_weekly_saving]
                  extra_savings_entry_count += 1
                  extra_savings_transaction_entry = te 
                end
              end
              
              
              principal_transaction_entry_count.should  ==  @number_of_weeks
              savings_transaction_entry_count.should  == @number_of_weeks
              interest_transaction_entry_count.should == @number_of_weeks
            end
            
            it "should increase the member's savings by number_of_weeks* min_savings" do
              final_total_savings = @selected_member.total_savings
              savings_difference = final_total_savings - @initial_total_savings
              expected_savings_difference  = @group_loan_product.min_savings * @number_of_weeks 
              savings_difference.should == expected_savings_difference
            end
            
          end #end of the context "post condition of multiple weeks , no extra savings, no savings withdrawal" 
        end# end of context "weekly_payment_structured_multiple_weeks"
        
        context "weekly_payment_structured_multiple_weeks_extra_savings " do 
          before(:each) do
            savings_amount = 2* @group_loan_product.total_weekly_payment
            TransactionActivity.create_independent_savings( @selected_member, savings_amount, @field_worker )
            @number_of_weeks = 2
            
            @cash_amount =  (@number_of_weeks + 1 )* @group_loan_product.total_weekly_payment  
            @savings_withdrawal_amount  = BigDecimal("0")
            @initial_total_savings = @selected_member.total_savings
            @structured_transaction = TransactionActivity.create_structured_multiple_payment(
                @selected_member, #member
                @weekly_task,  # the weekly task
                @field_worker, # the field worker 
                @cash_amount,   # the cash payment 
                @savings_withdrawal_amount,  #savings withdrawal
                @number_of_weeks)# number of weeks
          end
          
          it "should produce 7 transaction entries: 2 principal, 2 interest, 2 savings, 1 extra savings" do
            principal_transaction_entry = 1 
            interest_transaction_entry =  1
            min_savings_transaction_entry =  1
            total_basic_weekly_transaction_entry_no_extra_savings = principal_transaction_entry + 
                            interest_transaction_entry + 
                            min_savings_transaction_entry
            extra_savings_transaction_entry = 1 
            
            total_transaction_entry = total_basic_weekly_transaction_entry_no_extra_savings * @number_of_weeks + 
                                extra_savings_transaction_entry
            
            @structured_transaction.should have(total_transaction_entry).transaction_entries 
          end
          
          it "should produce an extra savings with amount: cash + savings_withdrawal - number_of_weeks*weekly_payment_amount" do
            expected_extra_savings = @cash_amount + @savings_withdrawal_amount  -
                            ( @number_of_weeks * @group_loan_product.total_weekly_payment)
                            
            extra_savings_transaction_entry = @structured_transaction.transaction_entries.where(
                              :transaction_entry_code => TRANSACTION_ENTRY_CODE[:extra_weekly_saving]).first
                              
            extra_savings_transaction_entry.amount.should == expected_extra_savings
          end
          
          it "should increase the savings by number_of_weeks*min_savings + (cash_amount - number_of_weeks*weekly_payment_amount)" do
            final_total_savings = @selected_member.total_savings
            
            actual_savings_difference = final_total_savings - @initial_total_savings
            expected_savings_difference = @number_of_weeks*@group_loan_product.min_savings + 
                        (@cash_amount - @number_of_weeks*@group_loan_product.total_weekly_payment )
            actual_savings_difference.should == expected_savings_difference
          end
        end
        context "weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal " 
        context " weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal_extra_savings" 
        
     
      end
      
      
    end
  end # end of "Weekly Loan Payment Transaction Activity"
  
  describe "Backlog Payment Transaction Activity" do 
    context "basic single backlog payment" do
    end
    context "multiple backlog payments + structured" do
    end
    it "records the principal, compulsory savings, and interest payment"
    it "might contain the penalty payment for being late, in which the rule we haven't understood"
  end
  
  it "is storing reference to the loan type, either group_loan or backlog payment, or single loan"
  it "has loan amount that is equal to the amoung of money exchanging hands from member to employee or vice versa"
  it "won't create double transaction activities "
  
  describe "Group Loan Default Resolution Transaction Activity" do
    it 'records the payment from all member, the minimum denomination is 500 rupiah (up rounded)'
    it "records the excess due to rounding as rounding payment"
  end
end