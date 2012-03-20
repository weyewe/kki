# require 'rubygems'
# require 'openssl'
# require 'json'

module ApplicationHelper
  ACTIVE = 'active'
  REVISION_SELECTED = "selected"
  NEXT_BUTTON_TEXT = "Next &rarr;"
  PREV_BUTTON_TEXT = " &larr; Prev "
  
=begin
  For printing numbers (money)
=end

  def print_money(value)
    number_with_delimiter( value , :delimiter => ",")
  end
  
  
=begin
  For the grade display 
=end
  def get_colspan( closed_projects )
    length = closed_projects.length
    if length == 0 
      return 1 
    else
      return length 
    end
  end
  

=begin
  Getting prev and next button for the pictures#show
=end
  def get_next_project_picture( pic , is_grading_mode)
    next_pic = pic.next_pic
    
    if not next_pic.nil?
      destination_url = ""
      if not is_grading_mode
        destination_url = project_submission_picture_url( pic.project_submission, next_pic)
      else
        destination_url = grade_project_submission_picture_url( next_pic ) 
      end
      
      
      return  create_galery_navigation_button( NEXT_BUTTON_TEXT, "next",destination_url )
    else
      ""
    end
  end
  
  def get_previous_project_picture( pic , is_grading_mode )
    prev_pic = pic.prev_pic
    
    if not prev_pic.nil?
      
      destination_url = ""
      if not is_grading_mode
        destination_url = project_submission_picture_url( pic.project_submission, prev_pic)
      else
        destination_url = grade_project_submission_picture_url( prev_pic ) 
      end
      
      
      return  create_galery_navigation_button( PREV_BUTTON_TEXT, "previous", destination_url)
      
    else
      ""
    end
    
  end
  
  
  
  def create_galery_navigation_button( text, class_name, destination_url )
    button = ""
    button << "<li class=#{class_name}>"
    button << link_to("#{text}".html_safe, destination_url )
    button << "</li>"
    
  end
  
  # <li class="previous">
  #   <a href="#">&larr; Prev</a>
  # </li>
  # <li class="next">
  #   <a href="#">Next &rarr;</a>
  # </li>
  
  
  
=begin
  Showing the revisions in the pictures#show
=end
  
  def class_for_current_displayed_revision(revision, current_display)
    if revision.id == current_display.id 
      return REVISION_SELECTED
    else
      return ""
    end
  end
  
=begin
  Assigning activity:
  1. Assigning student to the class
  2. Assigning teacher to the course etc
=end
  
  def get_checkbox_value(checkbox_value )
    if checkbox_value == true
      return TRUE_CHECK
    else
      return FALSE_CHECK
    end
  end
  
  
=begin
  General command to create Guide in all pages
=end 
  def create_guide(title, description)
    result = ""
    result << "<div class='explanation-unit'>"
    result << "<h1>#{title}</h1>"
    result << "<p>#{description}</p>"
    result << "</div>"
  end
  
  def create_breadcrumb(breadcrumbs)
    
    if (  breadcrumbs.nil? ) || ( breadcrumbs.length ==  0) 
      # no breadcrumb. don't create 
    else
      breadcrumbs_result = ""
      breadcrumbs_result << "<ul class='breadcrumb'>"
      
      puts "After the first"
      
      
      breadcrumbs[0..-2].each do |txt, path|
        breadcrumbs_result  << create_breadcrumb_element(    link_to( txt, path ) ) 
      end 
      
      puts "After the loop"
      
      last_text = breadcrumbs.last.first
      last_path = breadcrumbs.last.last
      breadcrumbs_result << create_final_breadcrumb_element( link_to( last_text, last_path)  )
      breadcrumbs_result << "</ul>"
      return breadcrumbs_result
    end
    
    
  end
  
  def create_breadcrumb_element( link ) 
    element = ""
    element << "<li>"
    element << link
    element << "<span class='divider'>/</span>"
    element << "</li>"
    
    return element 
  end
  
  def create_final_breadcrumb_element( link )
    element = ""
    element << "<li class='active'>"
    element << link 
    element << "</li>"
    
    return element
  end
  
  
=begin
  Process Navigation related activity
=end  

  
  def get_process_nav( symbol, params)
    
    if symbol == :branch_manager
      return create_process_nav(BRANCH_MANAGER_PROCESS_LIST, params )
    end
    
    if symbol == :loan_officer 
      return create_process_nav(LOAN_OFFICER_PROCESS_LIST, params )
    end
    
    if symbol == :cashier
      return create_process_nav(CASHIER_PROCESS_LIST, params )
    end
    
    if symbol == :field_worker 
      return create_process_nav( FIELD_WORKER_PROCESS_LIST, params )
    end
   
  end
  
  
  
  
  protected 
  
  #######################################################
  #####
  #####     Start of the process navigation code 
  #####
  #######################################################
   
  def create_process_nav( process_list, params )
     result = ""
     result << "<ul class='nav nav-list'>"
     result << "<li class='nav-header'>  "  + 
                 process_list[:header_title] + 
                 "</li>"         

     process_list[:processes].each do |process|
       result << create_process_entry( process, params )
     end

     result << "</ul>"

     return result
   end
   
   
  
  
  
  def create_process_entry( process, params )
    is_active = is_process_active?( process[:conditions], params)
    
    process_entry = ""
    process_entry << "<li class='#{is_active}'>" + 
                      link_to( process[:title] , extract_url( process[:destination_link] )    )
    
    return process_entry
  end
  
  def is_process_active?( active_conditions, params  )
    active_conditions.each do |condition|
      if condition[:controller] == params[:controller] &&
        condition[:action] == params[:action]
        return ACTIVE
      end

    end

    return ""
  end
  
  def extract_url( some_url )
    if some_url == '#'
      return '#'
    end
    
    eval( some_url ) 
  end
  
  
  
  #######################################################
  #####
  #####     Start of the process navigation KONSTANT
  #####
  #######################################################
  
  BRANCH_MANAGER_PROCESS_LIST = {
    :header_title => "BRANCH MANAGER",
    :processes => [
      {
        :title => "Create Loan Product",
        :destination_link => 'new_group_loan_product_url',
        :conditions => [
          {
            :controller => 'group_loan_products',
            :action => 'new'
          },
          {
            :controller => 'group_loan_products',
            :action => 'create'
          }
        ]
      },
      {
        :title => "Approval Pending",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'loan_product',
            :action => 'banzai'
          }
        ]
      }
    ]
  }
  
  LOAN_OFFICER_PROCESS_LIST = {
    :header_title => "LOAN_OFFICER",
    :processes => [
      {
        :title => "Add Member",
        :destination_link => 'new_member_url',
        :conditions => [
          {
            :controller => 'members',
            :action => 'new'
          },
          {
            :controller => "members",
            :action => "create"
          }
        ]
      },
      {
        :title => "Create GroupLoan",
        :destination_link => 'new_group_loan_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'new'
          }
        ]
      },
      {
        :title => "Assign Member to GroupLoan",
        :destination_link => 'select_group_loan_to_assign_member_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_assign_member'
          },
          {
            :controller => "group_loan_memberships",
            :action => "new"
          }
        ]
      },
      {
        :title => "Assign Loan To Member",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'loan_product',
            :action => 'banzai'
          }
        ]
      }
    ]
  }
  
  CASHIER_PROCESS_LIST = {
    :header_title => "CASHIER",
    :processes => [
      {
        :title => "Approve Group Weekly Payment",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'enrollments',
            :action => 'kungfu'
          }
        ]
      },
      {
        :title => "Approve Loan Disbursment",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'loan_product',
            :action => 'banzai'
          }
        ]
      },
      {
        :title => "Approve Special Payment",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'loan_product',
            :action => 'banzai'
          }
        ]
      },
      {
        :title => "Approves Setup Payment",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'loan_product',
            :action => 'banzai'
          }
        ]
      }
    ]
  }
  
  
  FIELD_WORKER_PROCESS_LIST = {
    :header_title => "FIELD WORKER",
    :processes => [
      {
        :title => "Setup Payment",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'enrollments',
            :action => 'kungfu'
          }
        ]
      },
      {
        :title => "Group Weekly Payment",
        :destination_link => 'root_url',
        :conditions => [
          {
            :controller => 'loan_product',
            :action => 'banzai'
          }
        ]
      }
    ]
  }
  
  
  
end
