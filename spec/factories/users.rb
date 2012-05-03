FactoryGirl.define do
  factory :user do
    email "willy@gmail.com"
    password "willy1234"
    password_confirmation "willy1234"
  end
  
  factory :branch_manager, parent: :user do 
    email "branch_manager@gmail.com"
    # created_user.after_create { |u| FactoryGirl(:branch_manager_role_assignment) }
    after_create do |x|  
      # cilincing_office = Office.find_by_name("Cilincing Office")
      x.offices << FactoryGirl.create(:cilincing_office)  
      x.save
      job_attachment = x.get_active_job_attachment 
      
      branch_manager_role = Role.find_by_name(USER_ROLE[:branch_manager]) || FactoryGirl.create(:branch_manager_role)
      job_attachment.roles <<  branch_manager_role
      job_attachment.save
    end
    
  end
  
  factory :loan_officer, parent: :user do  
    email "loan_officer@gmail.com"
    after_create do |x|  
      x.offices << FactoryGirl.create(:cilincing_office)  
      x.save
      job_attachment = x.get_active_job_attachment 
      
      branch_manager_role = Role.find_by_name(USER_ROLE[:loan_officer]) || FactoryGirl.create(:loan_officer_role)
      job_attachment.roles <<  branch_manager_role
       
      job_attachment.save
    end
  end
  
  factory :cashier, parent: :user do  
    email "cashier@gmail.com"
    after_create do |x|  
      x.offices << FactoryGirl.create(:cilincing_office)  
      x.save
      job_attachment = x.get_active_job_attachment 
      
      branch_manager_role = Role.find_by_name(USER_ROLE[:cashier]) || FactoryGirl.create(:cashier_role)
      job_attachment.roles <<  branch_manager_role
       
      job_attachment.save
    end
  end
  
  factory :field_worker, parent: :user do  
    email "field_worker@gmail.com"
    after_create do |x|  
      x.offices << FactoryGirl.create(:cilincing_office)  
      x.save
      job_attachment = x.get_active_job_attachment 
      
      branch_manager_role = Role.find_by_name(USER_ROLE[:field_worker]) || FactoryGirl.create(:field_worker_role)
      job_attachment.roles <<  branch_manager_role
       
      job_attachment.save
    end
  end
  
  
  
end
