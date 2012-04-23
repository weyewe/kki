class ApplicationController < ActionController::Base
  include Transloadit::Rails::ParamsDecoder
  protect_from_forgery
  before_filter :authenticate_user!

  layout :layout_by_resource

  def layout_by_resource
    if devise_controller? && resource_name == :user && action_name == 'new'
      "devise"
    else
      "application"
    end
  end
  
  
  def after_sign_in_path_for(resource)
    active_job_attachment  = current_user.active_job_attachment 
    if current_user.has_role?( :branch_manager, active_job_attachment)
      puts "user has role branch_manager!\n"*10
      return new_group_loan_product_url
    end
    
    if current_user.has_role?(:loan_officer, active_job_attachment)
      puts "user has role loan_officer!\n"*10
      return new_member_url
    end
    
    if current_user.has_role?(:field_worker, active_job_attachment)
      puts "user has role field_worker!\n"*10
      return select_group_loan_for_setup_payment_url
    end
    
    if current_user.has_role?(:cashier, active_job_attachment)
      puts "user has role field_worker!\n"*10
      return select_group_loan_for_setup_payment_collection_approval_url
    end
    
    
    
    puts "God.. no role at all.. something messed up with the seeds\n"*10
    
    
    # if current_user.has_role?(:cashier, active_job_attachment)
    #    return project_submissions_url
    #  end
    #  
    #  if current_user.has_role?(:field_worker, active_job_attachment)
    #    return project_submissions_url
    #  end
    #  
  end


  def set_breadcrumb_for object, destination_path, opening_words
    # puts "THIS IS WILLLLLY\n"*10
    # puts destination_path
    add_breadcrumb "#{opening_words}", destination_path
  end

  protected
  def add_breadcrumb name, url = ''
    @breadcrumbs ||= []
    url = eval(url) if url =~ /_path|_url|@/
    @breadcrumbs << [name, url]
  end

  def self.add_breadcrumb name, url, options = {}
    before_filter options do |controller|
      controller.send(:add_breadcrumb, name, url)
    end
  end

  
end
