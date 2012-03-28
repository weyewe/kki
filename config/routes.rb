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
  end
  resources :group_loan_memberships
  resources :group_loan_subcriptions
  resources :members 

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

=begin
  Transaction routes 
=end
  resources :transaction_activities do
    resources :transaction_entries
  end
  
  match 'transaction_activity/setup_payment' => 'transaction_activities#create_transaction_activity_for_setup_payment', :as => :create_transaction_activity_for_setup_payment
  match 'execute_setup_fee_collection_finalization' => "group_loans#execute_setup_fee_collection_finalization", :as => :execute_setup_fee_collection_finalization, :method => :post 
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
