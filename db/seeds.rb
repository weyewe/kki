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
member_hash = {}   
(1..TOTAL_MEMBER_COUNT).each do |x|
  member_hash[x] = Member.create :name => "Member #{x}", 
                :id_card_no => "1233435253#{x}",  :village_id => first_village.id,
                :commune_id => commune.id, :neighborhood_no => x,
                :address => "Jalan Tikus Gang 33252 no 55 #{x}",
                :creator_id => loan_officer.id,
                :office_id => cilincing_office.id
end            
  

puts " member creation is done "


