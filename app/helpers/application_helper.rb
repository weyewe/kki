# require 'rubygems'
# require 'openssl'
# require 'json'

module ApplicationHelper
  ACTIVE = 'active'
  REVISION_SELECTED = "selected"
  NEXT_BUTTON_TEXT = "Next &rarr;"
  PREV_BUTTON_TEXT = " &larr; Prev "
  
  TRANSACTION_ENTRY_DESCRIPTION_HASH = {
    1 => "Deposito awal",
    2 => "Tabungan awal dari pinjaman group",
    3 => "Biaya Administrasi",
    4 => "Pembayaran pinjaman dasar mingguan",
    5 => "Pembayaran bunga mingguan", 
    6 => "Pembayaran tabungan wajib mingguan",
    7 => "Pembayaran denda keterlambatan",
    8 => "Pembayaran extra tabungan mingguan",
    
    
    101 => "Pengembalian deposito awal",
    102 => "Penarikan dana lunak dari tabungan",
    103 => "Penarikan dana real dari tabungan",
    104 => "Pemberian pinjaman"
  }
  
  

  
=begin
  Group Member management 
=end  

  def select_total_subgroups_to_be_created(group_loan)
    array = ""
   
    
    (1..10).each do |sub_groups_count|
      if group_loan.sub_groups.count == sub_groups_count
        array << "<option value='#{sub_groups_count}' selected='selected'>#{sub_groups_count} </option>"
      else
        array << "<option value='#{sub_groups_count}'>#{sub_groups_count} </option>"
      end
    end
  
    return array
  end



  def extract_member_name(member)
    if member.nil? 
      return "--"
    else
      member.name 
    end
  end

=begin
  For printing the transaction entry details 
=end
  def transaction_entry_description(transaction_entry)
    #transaction_entry_code
    #transaction_entry_action_type
    TRANSACTION_ENTRY_DESCRIPTION_HASH[ transaction_entry.transaction_entry_code ]
  end
  
  def transaction_entry_value_display(transaction_entry)
    if transaction_entry.transaction_entry_action_type == TRANSACTION_ENTRY_ACTION_TYPE[:inward]
      print_money( transaction_entry.amount ) 
    elsif transaction_entry.transaction_entry_action_type == TRANSACTION_ENTRY_ACTION_TYPE[:outward]
      "(-" + print_money( transaction_entry.amount ) + ")"
    end
  end


  
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
    
    if symbol == :group_management
      return create_process_nav(GROUP_MANAGEMENT_PROCESS_LIST, params )
    end
    
    if symbol == :cashier
      return create_process_nav(CASHIER_PROCESS_LIST, params )
    end
    
    if symbol == :savings
      return create_process_nav(SAVINGS_PROCESS_LIST, params )
    end
    
    if symbol == :field_worker 
      return create_process_nav( FIELD_WORKER_PROCESS_LIST, params )
    end
    
    if symbol == :group_employee_management
      return create_process_nav(GROUP_EMPLOYEE_MANAGEMENT_PROCESS_LIST, params )
    end
   
    if symbol == :loan_inspector
      return create_process_nav(LOAN_INSPECTOR_PROCESS_LIST, params )
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
        :title => "Pending Approval",
        :destination_link => 'select_group_loan_to_start_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_start'
          }
        ]
      },
      {
        :title => "Monitor Progress",
        :destination_link => 'select_started_group_loan_to_be_managed_url',
        :conditions => [
          {
            :controller => "group_loans",
            :action => "select_started_group_loan_to_be_managed"
          }
        ]
      },
      {
        :title => "Declare Default Loan",
        :destination_link => "select_group_loan_to_be_declared_as_default_url",
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_be_declared_as_default'
          }
        ]
      },
      # {
      #         :title => "Monitor Default Loan Resolution",
      #         :destination_link => "select_group_loan_monitor_default_loan_resolution_url",
      #         :conditions => [
      #           :controller => "group_loans",
      #           :action => 'select_group_loan_monitor_default_loan_resolution'
      #         ]
      #       },
      {
        :title => "Closed Group Loan",
        :destination_link => "select_closed_group_loan_for_history_url",
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_closed_group_loan_for_history'
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
        :title => "Assign GroupLoanProduct",
        :destination_link => 'select_group_loan_to_group_loan_product_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_group_loan_product'
          },
          {
            :controller => "group_loan_subcriptions",
            :action => "new"
          }
        ]
      },
      {
        :title => "Finalize Group Loan",
        :destination_link => "select_group_loan_for_finalization_url",
        :conditions => [
          {
            :controller => "group_loans",
            :action => "select_group_loan_for_finalization"
          }
        ]
      }
    ]
  }
  
  GROUP_MANAGEMENT_PROCESS_LIST = {
    :header_title => "Group Member Management",
    :processes => [
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
        :title => "Select Group Leader",
        :destination_link => 'select_group_loan_to_select_group_leader_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_select_group_leader'
          },
          {
            :controller => 'group_loans',
            :action => 'select_group_leader_from_member'
          }
        ]
      },
      {
        :title => "Create SubGroup",
        :destination_link => 'select_group_loan_to_create_sub_group_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_create_sub_group'
          },
          {
            :controller => "sub_groups",
            :action => "new"
          }
        ]
      },
      {
        :title => "Assign Member to Subgroup",
        :destination_link => 'select_group_loan_to_assign_member_to_sub_group_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_assign_member_to_sub_group'
          },
          {
            :controller => "sub_groups",
            :action => "select_sub_group_to_assign_members"
          },
          {
            :controller => "sub_groups",
            :action => "assign_member_to_sub_group"
          }
        ]
      },
      {
        :title => "Select Sub Group Leader",
        :destination_link => 'select_group_loan_to_select_sub_group_leader_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_select_sub_group_leader'
          },
          {
            :controller => "sub_groups",
            :action => "select_sub_group_to_pick_leader"
          },
          {
            :controller => "sub_groups",
            :action => "select_sub_group_leader_from_sub_group"
          }
        ]
      }
    ]
  }
  
  CASHIER_PROCESS_LIST = {
    :header_title => "CASHIER",
    :processes => [
      {
        :title => "Approves Setup Payment ",
        :destination_link => 'select_group_loan_for_setup_payment_collection_approval_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_setup_payment_collection_approval'
          }
        ]
      },
      {
        :title => "Loan Disbursement",
        :destination_link => 'select_group_loan_for_loan_disbursement_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_loan_disbursement'
          },
          {
            :controller => "group_loan_memberships",
            :action => "group_loan_disbursement_recipients"
          }
        ]
      },
      {
        :title => "Approve Group Weekly Payment",
        :destination_link => 'list_pending_weekly_collection_approval_url',
        :conditions => [
          {
            :controller => 'weekly_tasks',
            :action => 'list_pending_weekly_collection_approval'
          }
        ]
      },
      {
        :title => "Approve Backlog Payment",
        :destination_link => 'select_group_loan_for_backlog_payment_approval_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_backlog_payment_approval'
          },
          {
            :controller => "backlog_payments", 
            :action => "select_pending_backlog_to_be_approved"
          }
        ]
      }
    ]
  }
  
  SAVINGS_PROCESS_LIST ={
    :header_title => "Savings",
    :processes => [
      {
        :title => "Savings withdrawal",
        :destination_link => "root_url",
        :conditions => [
          {
            :controller => '',
            :action => ''
          }
        ]
      }
    ]
  }
  
  GROUP_EMPLOYEE_MANAGEMENT_PROCESS_LIST = {
    :header_title => "Group Officer Assignment",
    :processes => [
      {
        :title => "Assign Field Worker",
        :destination_link => "select_group_loan_to_create_field_worker_assignment_url",
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_create_field_worker_assignment'
          },
          {
            :controller => "group_loan_assignments",
            :action => 'new_field_worker_assignment_to_employee'
          }
        ]
      },
      {
        :title => "Assign Loan Inspector",
        :destination_link => "select_group_loan_to_create_loan_inspector_assignment_url",
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_create_loan_inspector_assignment'
          },
          {
            :controller => "group_loan_assignments",
            :action => 'new_loan_inspector_assignment_to_employee'
          }
        ]
      }
    ]
  }
  
  LOAN_INSPECTOR_PROCESS_LIST = {
    :header_title => "Loan Inspector",
    :processes => [
      {
        :title => "Finalize Financial Education Attendance",
        :destination_link => "select_group_loan_for_financial_education_finalization_url",
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_financial_education_finalization'
          },
          {
            :controller => "group_loans",
            :action => 'finalize_financial_education_attendance'
          }
        ]
      },
      {
        :title => "Finalize Loan Disbursement Attendance",
        :destination_link => "select_group_loan_for_loan_disbursement_attendance_finalization_url",
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_loan_disbursement_attendance_finalization'
          },
          {
            :controller => "group_loans",
            :action => 'finalize_loan_disbursement_attendance'
          }
        ]
      }
    ]
  }
  
  
  
  FIELD_WORKER_PROCESS_LIST = {
    :header_title => "FIELD WORKER",
    :processes => [
      {
        :title => "Financial Education Attendance",
        :destination_link => 'select_group_loan_for_financial_education_meeting_attendance_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_financial_education_meeting_attendance'
          },
          {
            :controller => "group_loans",
            :action => "mark_financial_education_attendance"
          }
        ]
      },
      {
        :title => "Loan Disbursement Attendance",
        :destination_link => 'select_group_loan_for_loan_disbursement_meeting_attendance_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_loan_disbursement_meeting_attendance'
          },
          {
            :controller => "group_loans",
            :action => "mark_loan_disbursement_attendance"
          }
        ]
      },
      {
        :title => "Weekly Meeting",
        :destination_link => 'select_group_loan_for_weekly_meeting_attendance_marking_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_weekly_meeting_attendance_marking'
          },
          {
            :controller => "weekly_tasks",
            :action => "select_weekly_meeting_for_attendance_marking"
          },
          {
            :controller => "weekly_tasks",
            :action => "mark_attendance"
          }
        ]
      },
      {
        :title => "Weekly Payment",
        :destination_link => 'select_group_loan_for_weekly_payment_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_weekly_payment'
          },
          {
            :controller => "weekly_tasks",
            :action => "select_weekly_meeting_for_weekly_payment"
          },
          {
            :controller => "weekly_tasks",
            :action => "make_member_payment"
          },
          {
            :controller => "weekly_tasks",
            :action => "special_weekly_payment_for_member"
          }
        ]
      },
      {
        :title => "Backlog Payment",
        :destination_link => "select_group_loan_for_backlog_weekly_payment_url",
        :conditions => [
          {
            :controller => "group_loans",
            :action => "select_group_loan_for_backlog_weekly_payment"
          },
          {
            :controller => "backlog_payments",
            :action => "index"
          },
          {
            :controller => "backlog_payments",
            :action => "pay_backlog_for_group_loan"
          }
        ]
      },
      {
        :title => "Loan Default Resolution",
        :destination_link => 'select_group_loan_for_loan_default_resolution_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_loan_default_resolution'
          },
          {
            :controller => "default_payments",
            :action => 'list_default_payment_for_clearance'
          },
          {
            :controller => "default_payments",
            :action => 'payment_for_default_resolution'
          }
        ]
      }
    ]
  }
  
  
  
end
