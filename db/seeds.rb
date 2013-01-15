=begin
  We need office. 
  Every employee is locked to an office
  Every member and group is locked to an office as well
  
  One regency (kabupaten) can have many offices
  One office handles at least 1 subdistrict (kecamatan)
=end

cilincing_office = Office.create :name => "Cilincing", :regency_id => NORTH_JAKARTA_REGENCY

=begin
  We need to create the geoscope of cilincing_office
=end

java_island = Island.create :name => "Java"
jakarta_province = Province.create :name => "Jakarta", :island_id => java_island.id
north_jakarta_regency = Regency.create :name => "Jakarta Utara", :province_id => jakarta_province.id
cilincing_subdistrict = Subdistrict.create :name => "Cilincing", :regency_id => north_jakarta_regency.id

=begin
  One office handles at least one subdistrict
  Office has_many :subdistricts through :geo_scopes
=end

cilincing_office.subdistricts << cilincing_subdistrict
cilincing_office.save


=begin
  creating all villages in Cilincing subdistrict

  Kali Baru, Cilincing dengan kode pos 14110
  Cilincing, Cilincing dengan kode pos 14120
  Semper Barat, Cilincing dengan kode pos 14130
  Semper Timur, Cilincing dengan kode pos 14130
  Sukapura, Cilincing dengan kode pos 14140
  Rorotan, Cilincing dengan kode pos 14140
  Marunda, Cilincing dengan kode pos 14150
  
  http://www.jakarta.go.id/jakv1/encyclopedia/detail/202
=end

cilincing_villages = [
  {
    :postal_code => 14110,
    :name => "Kali Baru", 
    :total_communes => 14 
  },
  {
    :postal_code => 14120,
    :name => "Cilincing", 
    :total_communes => 10
  },
  {
    :postal_code => 14130,
    :name => "Semper Barat", 
    :total_communes => 17
  },
  {
    :postal_code => 14130,
    :name => "Semper Timur", 
    :total_communes => 10
  },
  {
    :postal_code => 14140,
    :name => "Sukapura", 
    :total_communes => 10
  },
  {
    :postal_code => 14140,
    :name => "Rorotan", 
    :total_communes => 11
  },
  {
    :postal_code => 14150,
    :name => "Marunda", 
    :total_communes => 9
  }
]



cilincing_villages.each do |village|
  new_village = Village.create :name => village[:name], :postal_code => village[:postal_code], 
      :subdistrict_id => cilincing_subdistrict.id

  (1..village[:total_communes]).each do |x|
    Commune.create :village_id => new_village.id , :number => x 
  end
end

first_village = Village.first
# first_village.communes.create :number => 1


puts "Done creating regional master data"
=begin
Role creation
What are the roles in typical branch? 
1. Branch Manager
  -> Approve Group Creation
  -> Approve GroupLoan Disbursement 
  -> Approve Member Creation
  -> Closing Group Loan 
    - approve that everyone has paid
  -> Create Loan Product 
  -> Updating, cancelling all these informations 
  
  -> Add employee
    -> add role 
  -> Add greographical work scope (Kecamatan)
  
  
  Branch manager only acts as controller. Making sure that everyone is doing the right thing,
  and making the critical decision
  
2. Loan Officer
  -> Registering approved member
  -> Create group    
    -> Assign member to a group -> Pick a group leader 
    
  -> Create subgroup    
    -> Assign group member to the subgroup   -> Pick the subgroup leader
  
    
  
3. Field Worker 
  -> Add Payment
    Group Creation Payment:
    -> Admin Fee 
    -> Initial Savings
    
    Weekly Payment:
    -> Savings
    -> Principal
  
  -> Add Weekly Meeting 
    -> Meeting attendance
    
4. Cashier 
  -> Approve weekly payment 
  -> Unapprove weekly payment 
    -> resolve with the responsible field worker 
=end

Role.all.each { |role| role.destroy }

branch_manager_role = Role.create :name => "BranchManager"
loan_officer_role   = Role.create :name => "LoanOfficer"
field_worker_role   = Role.create :name => "FieldWorker"
cashier_role         = Role.create :name => "Cashier"

=begin
  Create the blank slate user 
=end
puts "Gonna create user "

branch_manager = cilincing_office.create_user( [branch_manager_role], 
  :email => 'branch_manager@gmail.com',
  :password => 'willy1234',
  :password_confirmation => 'willy1234'  ) 
  
  
# User.create :email => "branch_manager@gmail.com", :password => "willy1234",
#                   :password_confirmation => "willy1234" #, :office_id => cilincing_office.id
#                   
puts "Branch manager id is #{branch_manager.id}"

# loan_officer = User.create :email => "loan_officer@gmail.com", :password => "willy1234",
#                   :password_confirmation => "willy1234" #, :office_id => cilincing_office.id
#                 
loan_officer = cilincing_office.create_user( [loan_officer_role], 
                  :email => 'loan_officer@gmail.com',
                  :password => 'willy1234',
                  :password_confirmation => 'willy1234'  )
cashier = cilincing_office.create_user( [cashier_role], 
                  :email => "cashier@gmail.com", 
                  :password => "willy1234",
                  :password_confirmation => "willy1234" )  #, :office_id => cilincing_office.id

field_worker = cilincing_office.create_user( [field_worker_role],
                  :email => "field_worker@gmail.com", 
                  :password => "willy1234",
                  :password_confirmation => "willy1234" ) # , :office_id => cilincing_office.id
                  
field_worker_2 = cilincing_office.create_user( [field_worker_role],
                  :email => "field_worker_2@gmail.com", 
                  :password => "willy1234",
                  :password_confirmation => "willy1234" )# , :office_id => cilincing_office.id
      
puts "Done creating user. Gonna create job_attachment"            
=begin
  assign job_attachment to each of this user 
=end

# # cilincing_office.users << branch_manager 
# branch_manager_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
#               :user_id => branch_manager.id, :is_active => true )
# # cilincing_office.users << loan_officer 
# loan_officer_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
#               :user_id => loan_officer.id, :is_active => true )
# # cilincing_office.users << cashier 
# cashier_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
#               :user_id => cashier.id, :is_active => true )
# # cilincing_office.users << field_worker 
# field_worker_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
#               :user_id => field_worker.id, :is_active => true )
#               
# field_worker_2_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
#               :user_id => field_worker_2.id, :is_active => true )



puts "Done creating the blank slate user  user and the job attachment "

if not Rails.env.production? 
=begin
  Gonna add roles to the job attachment 
=end


puts "Done adding roles to the JobAttachment"


=begin  
  The whole business process is started by the branch manager creating 
    group loan product 
=end
puts "the first"
group_loan_product_a = GroupLoanProduct.create :principal => 20000, 
                                  :interest => 4000, 
                                  :min_savings => 8000, :total_weeks => 3 ,
                                  :admin_fee => 25000, :initial_savings => 15000,
                                  :creator_id => branch_manager.id ,
                                  :office_id => cilincing_office.id
puts "the second"
group_loan_product_b = GroupLoanProduct.create :principal => 25000, 
                                  :interest => 3000, 
                                  :min_savings => 8000, :total_weeks => 3 ,
                                  :admin_fee => 25000, :initial_savings => 20000,
                                  :creator_id => branch_manager.id,
                                  :office_id => cilincing_office.id 
                                  
puts "The third"
group_loan_product_c = GroupLoanProduct.create :principal => 40000, 
                                   :interest => 1000, 
                                   :min_savings => 8000, :total_weeks => 3 ,
                                   :admin_fee => 25000, :initial_savings => 50000,
                                   :creator_id => branch_manager.id ,
                                   :office_id => cilincing_office.id
                                  
                                
puts "done creating loan product" 


=begin
  Then, after the loan product has been created, the next role is to get member. (registering member) 
  In this scheme, the members registered by loan officer are the qualified member, 
  has been processsed offline, interviewed as well. 
  Now, someone has to create a group
  Commune == RW 
  Only people from the same commune that can borrow (group loan membership)
=end

first_village = Village.first
commune       = first_village.communes.first


  # auto create group name 
puts "create the member"
TOTAL_MEMBER_COUNT = 8    
member_hash = [] 
(1..TOTAL_MEMBER_COUNT).each do |x|
  member =   Member.create :name => "Member #{x}", 
                :id_card_no => "1233435253#{x}",  :village_id => first_village.id,
                :commune_id => commune.id, :neighborhood_no => x,
                :address => "Jalan Tikus Gang 33252 no 55 #{x}",
                :creator_id => loan_officer.id,
                :office_id => cilincing_office.id
                
  member_hash << member
end            
  

puts " member creation is done "
group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
   :commune_id => commune.id }, branch_manager)
   
puts "Group loan is created"

puts "BANZAI< GROUP LOAN IS #{group_loan.class}"


member_hash.each do |member|
  puts "BANZAI< MEMBER IS #{member.class}"
  GroupLoanMembership.create_membership( loan_officer, member, group_loan)
end

puts "Done creating glm"


group_loan.add_assignment(:field_worker, field_worker)
group_loan.add_assignment(:loan_inspector, branch_manager)

puts "Done add assignment to group loan"
group_loan_products_array = [
          group_loan_product_a,
          group_loan_product_b,
          group_loan_product_c
          ]
          
group_loan.group_loan_memberships.each do |glm|
  GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
end

puts "done adding group loan subcription"

sub_group_count = 2 
SubGroup.set_sub_groups( group_loan, sub_group_count )
first_sub_group = group_loan.sub_groups[0]
second_sub_group =  group_loan.sub_groups[1]

puts "done creating subgroup"
count = 0 
member_hash.each do |member|
  if count%2 == 0 
    first_sub_group.add_member( member )
  elsif count%2 == 1 
    second_sub_group.add_member( member )
  end
  count = count + 1 
end

puts "done adding member to subgroup"

group_loan.execute_propose_finalization( loan_officer )

puts "done propose finalization"

group_loan.start_group_loan( branch_manager )
puts "done start group loan"

group_loan.group_loan_memberships.each do |glm|
  glm.mark_financial_education_attendance( field_worker, true, group_loan  )
end

group_loan.propose_financial_education_attendance_finalization( field_worker) 

puts "Done financial education attendance"

group_loan.finalize_financial_attendance_summary(branch_manager)
group_loan.reload   # refresh the data  from db

puts "Finalize financial education"

group_loan.membership_to_receive_loan_disbursement.each do |glm|  
  glm.mark_loan_disbursement_attendance( field_worker, true, group_loan  )
end


group_loan.propose_loan_disbursement_attendance_finalization(field_worker)
group_loan.reload 



group_loan.group_loan_memberships.each do |glm|
  # important.. by default, set it to deduct setup fee from laon disbursment 
  glm.deduct_setup_payment_from_loan = true
  glm.save 
  TransactionActivity.execute_loan_disbursement( glm , field_worker )
  # the column has_received_disbursement is checked 
end


group_loan.finalize_loan_disbursement_attendance_summary(branch_manager )

group_loan.execute_finalize_loan_disbursement(cashier)
puts "finalized loan disbursement"


group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task|  
  group_loan.active_group_loan_memberships.includes(:member).each do |glm| 


    member =  glm.member 
    saving_book = member.saving_book
    initial_total_savings                = saving_book.total 
    initial_extra_savings                = saving_book.total_extra_savings
    initial_compulsory_savings           = saving_book.total_compulsory_savings

    glp = glm.group_loan_product



    #  mark member attendance  # the order doesn't matter 
    weekly_task.mark_attendance_as_present( glm.member, field_worker )
    # do payment 
    weekly_task = group_loan.currently_executed_weekly_task

    
    cash_payment = glp.total_weekly_payment
    savings_withdrawal = BigDecimal("0")
    number_of_weeks = 1 
    number_of_backlogs = 0 
    a = TransactionActivity.create_generic_weekly_payment(
      weekly_task, 
      glm,
      field_worker,
      cash_payment,
      savings_withdrawal, 
      number_of_weeks,
      number_of_backlogs,
      false
    )





    saving_book.reload

    final_total_savings      = saving_book.total 
    final_extra_savings      = saving_book.total_extra_savings
    final_compulsory_savings = saving_book.total_compulsory_savings
    diff = final_total_savings - initial_total_savings
    diff_extra_savings = final_extra_savings - initial_extra_savings
    diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings



  end
  weekly_task.close_weekly_meeting(field_worker)
  weekly_task.close_weekly_payment( field_worker )
  weekly_task.approve_weekly_payment_collection( cashier ) 
end



puts "Done with all weekly payments"

group_loan.reload
group_loan.propose_default_payment_execution( field_worker )

puts "Done with default payment execution propose"

group_loan.execute_default_payment_execution( cashier ) 

puts "Default payment executed by cashier"

group_loan.close_group_loan(branch_manager)

puts "Group loan is closed by branch manager"

puts "HAHAUEHEUAHUEHOAHUAEHRAE WE ARE DONE " if group_loan.is_closed? 

###############################
###############
############### => End of development only seeds 
###############
################################


# group_loan.start_group_loan_savings_disbursement(cashier)
end 

# puts test test test 
