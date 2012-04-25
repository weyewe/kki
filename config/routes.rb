Debita46::Application.routes.draw do
  devise_for :users, :controllers => {:registrations => "registrations"}
  
  resources :users 
  
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

  match 'select_group_loan_to_assign_member' => "group_loans#select_group_loan_to_assign_member", :as => :select_group_loan_to_assign_member
  match 'select_group_loan_to_group_loan_product' => "group_loans#select_group_loan_to_group_loan_product", :as => :select_group_loan_to_group_loan_product
  match 'select_group_loan_for_finalization' => "group_loans#select_group_loan_for_finalization", :as => :select_group_loan_for_finalization
  match 'execute_propose_finalization' => "group_loans#execute_propose_finalization", :as => :execute_propose_finalization, :method => :post 

=begin
  Branch Manager Routes
=end
  match 'select_group_loan_to_start' => "group_loans#select_group_loan_to_start", :as => :select_group_loan_to_start
  match 'execute_start_group_loan' => "group_loans#execute_start_group_loan", :as => :execute_start_group_loan, :method => :post 
  match 'select_started_group_loan_to_be_managed' => "group_loans#select_started_group_loan_to_be_managed", :as => :select_started_group_loan_to_be_managed
  
=begin
  Field Worker Routes
=end
  match 'select_group_loan_for_setup_payment' => "group_loans#select_group_loan_for_setup_payment", :as => :select_group_loan_for_setup_payment
  match 'group_loan/:group_loan_id/group_loan_memberships_for_setup_fee' => "group_loan_memberships#group_loan_memberships_for_setup_fee", :as => :group_loan_memberships_for_setup_fee
  
  match 'declare_setup_payment_by_loan_deduction' => "group_loan_memberships#declare_setup_payment_by_loan_deduction", :as => :declare_setup_payment_by_loan_deduction, :method => :post 
  
  match 'execute_setup_fee_collection_finalization' => "group_loans#execute_setup_fee_collection_finalization", :as => :execute_setup_fee_collection_finalization, :method => :post 
  
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
  # close weekly payment ?
  match 'close_weekly_payment' => "weekly_tasks#close_weekly_payment", :as => :close_weekly_payment, :method => :post 


  # backlog payment 
  match 'select_group_loan_for_backlog_weekly_payment' => "group_loans#select_group_loan_for_backlog_weekly_payment", :as => :select_group_loan_for_backlog_weekly_payment
  match 'pay_backlog_for_group_loan/:group_loan_id/member/:member_id' => "backlog_payments#pay_backlog_for_group_loan", :as => :pay_backlog_for_group_loan
  
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
  match 'execute_weekly_collection_approval' => "weekly_tasks#execute_weekly_collection_approval", :as => :execute_weekly_collection_approval, :method => :post

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
