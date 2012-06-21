Debita46::Application.routes.draw do
  devise_for :users, :controllers => {:registrations => "registrations"}
  
  resources :users 
  
  match 'raise_exception' => 'home#raise_exception', :as => :raise_exception 
  
  match 'create_new_employee' => "users#create_employee", :as => :create_new_employee
  match 'new_employee'        => "users#new_employee", :as => :new_employee
  match 'all_employees'       => "users#all_employees", :as => :all_employees
  match 'edit_employee/:username'       => "users#edit_employee", :as => :edit_employee
  match 'update_employee/:username'       => "users#update_employee", :as => :update_employee

  match 'dashboard'           => 'home#dashboard'  , :as => :dashboard
  root :to => 'home#dashboard'
  
=begin
  Branch Manager routes 
=end
  # match ''
  
  resources :group_loan_products 
  resources :group_loans  do
    resources :group_loan_memberships
    resources :group_loan_subcriptions
    resources :backlog_payments 
    resources :sub_groups
  end
  resources :group_loan_memberships
  resources :group_loan_subcriptions
  resources :members 
  
  resources :weekly_tasks do 
    resources :member_attendances
    resources :member_payments
  end

=begin
  Loan Officer Routes
=end
  match 'select_group_loan_to_assign_non_commune_constrained_member' => "group_loans#select_group_loan_to_assign_non_commune_constrained_member", :as => :select_group_loan_to_assign_non_commune_constrained_member
  match 'select_commune_for_group_loan_assignment/:group_loan_id' => "communes#select_commune_for_group_loan_assignment", :as => :select_commune_for_group_loan_assignment
  match 'list_members_in_commune/:commune_id/for_group_loan_membership_assignment/:group_loan_id' => "communes#list_members_in_commune", :as => :list_members_in_commune
  
  #  then, the new group loan memberships  summary
  match 'execute_group_loan_membership_creation_from_summary' => "group_loan_memberships#execute_group_loan_membership_creation_from_summary", :as => :execute_group_loan_membership_creation_from_summary, :method => :post 


  match 'select_group_loan_to_assign_member' => "group_loans#select_group_loan_to_assign_member", :as => :select_group_loan_to_assign_member
  match 'select_group_loan_to_group_loan_product' => "group_loans#select_group_loan_to_group_loan_product", :as => :select_group_loan_to_group_loan_product
  match 'select_group_loan_for_finalization' => "group_loans#select_group_loan_for_finalization", :as => :select_group_loan_for_finalization
  match 'execute_propose_finalization' => "group_loans#execute_propose_finalization", :as => :execute_propose_finalization, :method => :post 

# select group loan leader
  match 'select_group_loan_to_select_group_leader' => "group_loans#select_group_loan_to_select_group_leader", :as => :select_group_loan_to_select_group_leader
  match 'select_group_leader_from_member/:group_loan_id' => "group_loans#select_group_leader_from_member", :as => :select_group_leader_from_member
  match 'execute_select_group_leader' => "group_loans#execute_select_group_leader", :as => :execute_select_group_leader, :method => :post 
  

  
# select group loan to create subgroup 
  match 'select_group_loan_to_create_sub_group' => "group_loans#select_group_loan_to_create_sub_group", :as => :select_group_loan_to_create_sub_group

# assign member to the sub group 
  match 'select_group_loan_to_assign_member_to_sub_group' => "group_loans#select_group_loan_to_assign_member_to_sub_group", :as => :select_group_loan_to_assign_member_to_sub_group
  match 'select_sub_group_from/:group_loan_id/to_assign_members' => "sub_groups#select_sub_group_to_assign_members", :as => :select_sub_group_to_assign_members
  match 'assign_member_to_sub_group/:sub_group_id' => "sub_groups#assign_member_to_sub_group", :as => :assign_member_to_sub_group
  match 'execute_sub_group_assignment' => "sub_groups#execute_sub_group_assignment", :as => :execute_sub_group_assignment, :method => :post 
  
# select sub_group_leader  
  match 'select_group_loan_to_select_sub_group_leader' => "group_loans#select_group_loan_to_select_sub_group_leader", :as => :select_group_loan_to_select_sub_group_leader
  match 'select_sub_group_from/:group_loan_id/to_select_leader' => "sub_groups#select_sub_group_to_pick_leader", :as => :select_sub_group_to_pick_leader
  match 'select_sub_group_leader_from/:sub_group_id' => "sub_groups#select_sub_group_leader_from_sub_group", :as => :select_sub_group_leader_from_sub_group
  match 'execute_select_sub_group_leader' => "sub_groups#execute_select_sub_group_leader", :as => :execute_select_sub_group_leader, :method => :post


  # then, the post request -> different destination 
  match 'select_group_loan_to_create_field_worker_assignment' => "group_loans#select_group_loan_to_create_field_worker_assignment", :as => :select_group_loan_to_create_field_worker_assignment
  match 'new_field_worker_assignment_to_employee/:group_loan_id' => "group_loan_assignments#new_field_worker_assignment_to_employee", :as => :new_field_worker_assignment_to_employee
  match 'execute_field_worker_assignment' => "group_loan_assignments#execute_field_worker_assignment", :as => :execute_field_worker_assignment, :method => :post 
  
  match 'select_group_loan_to_create_loan_inspector_assignment' => "group_loans#select_group_loan_to_create_loan_inspector_assignment", :as => :select_group_loan_to_create_loan_inspector_assignment
  match 'new_loan_inspector_assignment_to_employee/:group_loan_id' => "group_loan_assignments#new_loan_inspector_assignment_to_employee", :as => :new_loan_inspector_assignment_to_employee
  match 'execute_loan_inspector_assignment' => "group_loan_assignments#execute_loan_inspector_assignment", :as => :execute_loan_inspector_assignment, :method => :post
  
  
=begin
  Branch Manager Routes
=end
  match 'select_group_loan_to_start' => "group_loans#select_group_loan_to_start", :as => :select_group_loan_to_start
  match 'execute_start_group_loan' => "group_loans#execute_start_group_loan", :as => :execute_start_group_loan, :method => :post 
  match 'select_started_group_loan_to_be_managed' => "group_loans#select_started_group_loan_to_be_managed", :as => :select_started_group_loan_to_be_managed
  
  
  match 'select_group_loan_to_be_declared_as_default' => "group_loans#select_group_loan_to_be_declared_as_default", :as => :select_group_loan_to_be_declared_as_default
  match 'execute_declare_default_group_loan' => "group_loans#execute_declare_default_group_loan", :as => :execute_declare_default_group_loan, :method => :post 
  
  # View the loan Progress and close the group loan 
  match "select_group_loan_monitor_default_loan_resolution" => "group_loans#select_group_loan_monitor_default_loan_resolution", :as => :select_group_loan_monitor_default_loan_resolution
  match 'close_group_loan' => "group_loans#close_group_loan", :as => :close_group_loan, :method => :post
  
  # preview the past group loans
  match 'select_closed_group_loan_for_history' => 'group_loans#select_closed_group_loan_for_history', :as => :select_closed_group_loan_for_history
=begin
  Field Worker Routes
=end
  match 'select_group_loan_for_setup_payment' => "group_loans#select_group_loan_for_setup_payment", :as => :select_group_loan_for_setup_payment
  match 'group_loan/:group_loan_id/group_loan_memberships_for_setup_fee' => "group_loan_memberships#group_loan_memberships_for_setup_fee", :as => :group_loan_memberships_for_setup_fee
  
  match 'declare_setup_payment_by_loan_deduction' => "group_loan_memberships#declare_setup_payment_by_loan_deduction", :as => :declare_setup_payment_by_loan_deduction, :method => :post 
  
  match 'execute_setup_fee_collection_finalization' => "group_loans#execute_setup_fee_collection_finalization", :as => :execute_setup_fee_collection_finalization, :method => :post 
  
  
  # for setup: financial education and the loan disbursement attendance 
  # the loan inspector has its counterpart as well
=begin
  MARKING FINANCIAL EDUCATION ATTENDANCE
=end
  match 'select_group_loan_for_financial_education_meeting_attendance' => "group_loans#select_group_loan_for_financial_education_meeting_attendance", :as => :select_group_loan_for_financial_education_meeting_attendance
  match 'mark_financial_education_attendance/:group_loan_id' => "group_loans#mark_financial_education_attendance", :as => :mark_financial_education_attendance
  match 'execute_financial_attendance_marking' => 'group_loan_memberships#execute_financial_attendance_marking', :as => :execute_financial_attendance_marking, :method => :post 
  match 'propose_finalization_for_financial_education' => "group_loans#propose_finalization_for_financial_education", :as => :propose_finalization_for_financial_education , :method => :post
  
  # => the loan inspector part
  match 'select_group_loan_for_financial_education_finalization' =>  "group_loans#select_group_loan_for_financial_education_finalization", :as => :select_group_loan_for_financial_education_finalization
  match 'finalize_financial_education_attendance/:group_loan_id' => "group_loans#finalize_financial_education_attendance", :as => :finalize_financial_education_attendance
  match 'execute_final_financial_attendance_marking' => 'group_loan_memberships#execute_final_financial_attendance_marking', :as => :execute_final_financial_attendance_marking, :method => :post 
  match 'execute_finalize_financial_education' => "group_loans#execute_finalize_financial_education", :as => :execute_finalize_financial_education , :method => :post
  
=begin
 MARKING LOAN DISBURSEMENT MEETING ATTENDANCE
=end
  match 'select_group_loan_for_loan_disbursement_meeting_attendance' => "group_loans#select_group_loan_for_loan_disbursement_meeting_attendance", :as => :select_group_loan_for_loan_disbursement_meeting_attendance
  match 'mark_loan_disbursement_attendance/:group_loan_id' => "group_loans#mark_loan_disbursement_attendance", :as => :mark_loan_disbursement_attendance
  match 'execute_loan_disbursement_attendance_marking' => 'group_loan_memberships#execute_loan_disbursement_attendance_marking', :as => :execute_loan_disbursement_attendance_marking, :method => :post 
  match 'propose_finalization_for_loan_disbursement' => "group_loans#propose_finalization_for_loan_disbursement", :as => :propose_finalization_for_loan_disbursement , :method => :post
  
  # => the loan inspector part
  match 'select_group_loan_for_loan_disbursement_attendance_finalization' =>  "group_loans#select_group_loan_for_loan_disbursement_attendance_finalization", :as => :select_group_loan_for_loan_disbursement_attendance_finalization
  match 'finalize_loan_disbursement_attendance/:group_loan_id' => "group_loans#finalize_loan_disbursement_attendance", :as => :finalize_loan_disbursement_attendance
  match 'execute_final_loan_disbursement_attendance_marking' => 'group_loan_memberships#execute_final_loan_disbursement_attendance_marking', :as => :execute_final_loan_disbursement_attendance_marking, :method => :post 
  match 'execute_finalize_loan_disbursement_attendance' => "group_loans#execute_finalize_loan_disbursement_attendance", :as => :execute_finalize_loan_disbursement_attendance , :method => :post
  
  
=begin
  LOAN DISBURSEMENT 
  when the loan inspector has approved the disbursement attendance, all the transaction activities
  will be automatically be created. A message is cc-ed to the cashier, notifying the amount of cash to be retrieved
=end
  


  # weekly meeting
  match 'select_group_loan_for_weekly_meeting_attendance_marking' => "group_loans#select_group_loan_for_weekly_meeting_attendance_marking", :as => :select_group_loan_for_weekly_meeting_attendance_marking
  match 'select_weekly_meeting_for_attendance_marking/:group_loan_id' => "weekly_tasks#select_weekly_meeting_for_attendance_marking", :as => :select_weekly_meeting_for_attendance_marking
  match 'mark_attendance/:group_loan_id/for_week/:weekly_task_id' => "weekly_tasks#mark_attendance", :as => :mark_attendance
  # close weekly meeting  
  match 'close_weekly_meeting' => "weekly_tasks#close_weekly_meeting", :as => :close_weekly_meeting, :method => :post 
  
  
  #weekly payment
  match 'select_group_loan_for_weekly_payment' => "group_loans#select_group_loan_for_weekly_payment", :as => :select_group_loan_for_weekly_payment
  match 'select_weekly_meeting_for_weekly_payment/:group_loan_id' => "weekly_tasks#select_weekly_meeting_for_weekly_payment", :as => :select_weekly_meeting_for_weekly_payment
  match 'make_member_payment/:group_loan_id/for_week/:weekly_task_id' => "weekly_tasks#make_member_payment", :as => :make_member_payment
  match 'special_weekly_payment_for_member/:group_loan_id/for_week/:weekly_task_id/member/:member_id' => "weekly_tasks#special_weekly_payment_for_member", :as => :special_weekly_payment_for_member
  # close weekly payment 
  match 'close_weekly_payment' => "weekly_tasks#close_weekly_payment", :as => :close_weekly_payment, :method => :post 



=begin
  GRACE PERIOD PAYMENT
=end
  match 'select_group_loan_for_backlog_grace_period_payment' => "group_loans#select_group_loan_for_backlog_grace_period_payment", :as => :select_group_loan_for_backlog_grace_period_payment
  match 'default_members_for_grace_period_payment/:group_loan_id' => "group_loans#default_members_for_grace_period_payment", :as => :default_members_for_grace_period_payment
  match 'grace_period_payment_calculator/:group_loan_membership_id' => "group_loans#grace_period_payment_calculator", :as => :grace_period_payment_calculator
  match 'create_transcation_activity_for_grace_period_payment/:group_loan_membership_id' => 'transaction_activities#create_transcation_activity_for_grace_period_payment', :as => :create_transcation_activity_for_grace_period_payment, :method => :post

  
  # Cashier approves grace period payment 
  
  match 'select_group_loan_for_grace_period_payment_approval' => "group_loans#select_group_loan_for_grace_period_payment_approval", :as => :select_group_loan_for_grace_period_payment_approval
  match 'select_pending_grace_period_payment_to_be_approved/:group_loan_id' => "transaction_activities#select_pending_grace_period_payment_to_be_approved", :as => :select_pending_grace_period_payment_to_be_approved
  match 'execute_backlog_payment_transaction_approval_by_cashier' => "transaction_activities#execute_backlog_payment_transaction_approval_by_cashier", :as => :execute_backlog_payment_transaction_approval_by_cashier, :method => :post

  # backlog payment , maybe not used
  match 'select_group_loan_for_backlog_weekly_payment' => "group_loans#select_group_loan_for_backlog_weekly_payment", :as => :select_group_loan_for_backlog_weekly_payment
  match 'pay_backlog_for_group_loan/:group_loan_id/member/:member_id' => "backlog_payments#pay_backlog_for_group_loan", :as => :pay_backlog_for_group_loan
  
=begin
  Loan Default RESOLUTION : PROPOSAL
=end
  #loan default resolution
  match 'select_group_loan_for_loan_default_resolution' =>"group_loans#select_group_loan_for_loan_default_resolution", :as => :select_group_loan_for_loan_default_resolution
  match 'standard_default_resolution_schema/:group_loan_id' => 'group_loans#standard_default_resolution_schema', :as => :standard_default_resolution_schema
  match 'custom_default_resolution_schema/:group_loan_id' => 'group_loans#custom_default_resolution_schema', :as => :custom_default_resolution_schema
  match 'execute_propose_standard_default_resolution' => 'group_loans#execute_propose_standard_default_resolution', :as => :execute_propose_standard_default_resolution, :method => :post
  
=begin
  Loan Default RESOLUTION : EXECUTION by Cashier 
=end
  match 'select_group_loan_for_default_resolution_execution' => "group_loans#select_group_loan_for_default_resolution_execution", :as => :select_group_loan_for_default_resolution_execution
  match 'execute_default_resolution' => "group_loans#execute_default_resolution", :as => :execute_default_resolution, :method => :post 
  
=begin
  Cashier Routes 
=end

  match 'select_group_loan_for_setup_payment_collection_approval' => "group_loans#select_group_loan_for_setup_payment_collection_approval", :as => :select_group_loan_for_setup_payment_collection_approval
  match 'approve_setup_fee_collection' => "group_loans#approve_setup_fee_collection", :as => :approve_setup_fee_collection, :method => :post

  match 'select_group_loan_for_loan_disbursement' => "group_loans#select_group_loan_for_loan_disbursement", :as => :select_group_loan_for_loan_disbursement
  match 'group_loan_disbursement_recipients/:group_loan_id' => "group_loan_memberships#group_loan_disbursement_recipients", :as => :group_loan_disbursement_recipients
  
  match 'execute_loan_disbursement_finalization' => "group_loans#execute_loan_disbursement_finalization", :as => :execute_loan_disbursement_finalization, :method => :post 

  # approve weekly payment by field_worker 
  # objective is to ensure the total amount from a given group is matching the value 
  match 'list_pending_weekly_collection_approval' => "weekly_tasks#list_pending_weekly_collection_approval", :as => :list_pending_weekly_collection_approval
  match 'details_weekly_collection/:weekly_task_id' =>  'weekly_tasks#details_weekly_collection' , :as => :details_weekly_collection
  match 'execute_weekly_collection_approval' => "weekly_tasks#execute_weekly_collection_approval", :as => :execute_weekly_collection_approval, :method => :post

  match 'select_group_loan_for_backlog_payment_approval' => "group_loans#select_group_loan_for_backlog_payment_approval", :as => :select_group_loan_for_backlog_payment_approval
  match 'select_pending_backlog_to_be_approved/:group_loan_id' => "backlog_payments#select_pending_backlog_to_be_approved", :as => :select_pending_backlog_to_be_approved
  match 'execute_backlog_payment_approval_by_cashier' => "backlog_payments#execute_backlog_payment_approval_by_cashier", :as => :execute_backlog_payment_approval_by_cashier, :method => :post
=begin
  Transaction routes 
=end
  resources :transaction_activities do
    resources :transaction_entries
  end
  
  match 'transaction_activity/setup_payment' => 'transaction_activities#create_transaction_activity_for_setup_payment', :as => :create_transaction_activity_for_setup_payment, :method => :post
  match 'transaction_activity/execute_loan_disbursement' => 'transaction_activities#execute_loan_disbursement', :as => :execute_loan_disbursement, :method => :post
  
  match 'transaction_activity/create_basic_weekly_payment/:weekly_task_id' => 'transaction_activities#create_basic_weekly_payment', :as => :create_basic_weekly_payment, :method => :post
  match 'transaction_activity/create_savings_only_as_weekly_payment/:weekly_task_id/member/:member_id' => 'transaction_activities#create_savings_only_as_weekly_payment', :as => :create_savings_only_as_weekly_payment, :method => :post
  match 'transaction_activity/create_structured_multiple_payment/:weekly_task_id/member/:member_id' => 'transaction_activities#create_structured_multiple_payment', :as => :create_structured_multiple_payment, :method => :post
  
  match 'transaction_activity/create_no_weekly_payment/:weekly_task_id/member/:member_id' => 'transaction_activities#create_no_weekly_payment', :as => :create_no_weekly_payment, :method => :post
  
  match 'transaction_activity/create_backlog_payment' => 'transaction_activities#create_backlog_payment', :as => :create_backlog_payment, :method => :post
 
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
