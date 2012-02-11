
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
All these roles are enough to manage branch office
=end

Assignment.all.each { |x| x.destroy }
User.all.each { |x| x.destroy }

branch_manager = User.create :email => "branch_manager@gmail.com", :password => "branch1234",
                  :password_confirmation => "branch1234"
branch_manager.roles << branch_manager_role
branch_manager.save
                  
loan_officer = User.create :email => "loan_officer@gmail.com", :password => "loan1234",
                  :password_confirmation => "loan1234"
loan_officer.roles << loan_officer_role
loan_officer.save      
            
                  
field_worker = User.create :email => "field_worker@gmail.com", :password => "field1234",
                  :password_confirmation => "field1234"
field_worker.roles << field_worker_role
field_worker.save                

cashier = User.create :email => "cashier@gmail.com", :password => "cashier1234",
                  :password_confirmation => "cashier1234"
cashier.roles << cashier_role
cashier.save
