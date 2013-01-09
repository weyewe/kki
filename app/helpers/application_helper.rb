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
    if value.nil?
      number_with_delimiter( 0 , :delimiter => "." )
    else
      number_with_delimiter( value.to_i , :delimiter => "." )
    end
    
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
        :title => "#{I18n.translate 'process.create_loan_product'}",
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
        :title => "#{I18n.t 'process.pending_approval'}",
        :destination_link => 'select_group_loan_to_start_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_start'
          }
        ]
      },
      {
        :title => "#{I18n.t 'process.monitor_progress'}",
        :destination_link => 'select_started_group_loan_to_be_managed_url',
        :conditions => [
          {
            :controller => "group_loans",
            :action => "select_started_group_loan_to_be_managed"
          }
        ]
      }, 
      {
        :title => "#{ I18n.translate 'process.closed_group_loan'}",
        :destination_link => "select_closed_group_loan_for_history_url",
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_closed_group_loan_for_history'
          }
        ]
      }
      # ,
      # {
      #   :title => "Voluntary Savings Adjustment",
      #   :destination_link => "new_voluntary_savings_adjustment_url",
      #   :conditions => [
      #     {
      #       :controller => 'savings_entries',
      #       :action => 'new_voluntary_savings_adjustment'
      #     }
      #   ]
      # }
    ]
  }
  
  LOAN_OFFICER_PROCESS_LIST = {
    :header_title => "#{I18n.t 'process.loan_officer'}",
    :processes => [
      {
        :title => "#{I18n.translate 'process.add_member'}",
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
        :title => "#{I18n.t 'process.create_group_loan'}",
        :destination_link => 'new_group_loan_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'new'
          }
        ]
      },
      {
        :title => "#{I18n.t 'process.assign_group_loan_product'}",
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
        :title => "#{I18n.translate "process.finalize_group_loan"}",
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
    :header_title => "#{I18n.translate 'process.group_member_management'}",
    :processes => [
      {
        :title => "#{I18n.translate 'process.member_assignment'}",
        :destination_link => 'select_group_loan_to_assign_non_commune_constrained_member_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_assign_non_commune_constrained_member'
          },
          {
            :controller => "communes",
            :action => "select_commune_for_group_loan_assignment"
          },
          {
            :controller => 'communes',
            :action => "list_members_in_commune"
          }
        ]
      },
      {
        :title => "#{I18n.t 'process.membership_summary'} ",
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
        :title => "#{I18n.t 'process.select_group_leader'}",
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
        :title => "#{I18n.translate 'process.create_sub_group'}",
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
        :title => "#{I18n.t 'process.assign_to_sub_group'}",
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
        :title => "#{I18n.t 'process.select_sub_group_leader'}",
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
        :title => "#{I18n.translate 'process.loan_disbursement'}",
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
        :title => "#{I18n.t 'process.weekly_payment'}",
        :destination_link => 'list_pending_weekly_collection_approval_url',
        :conditions => [
          {
            :controller => 'weekly_tasks',
            :action => 'list_pending_weekly_collection_approval'
          },
          {
            :controller => 'weekly_tasks',
            :action => 'details_weekly_collection'
          }
        ]
      },
      {
        :title => "#{I18n.translate 'process.independent_payment'}",
        :destination_link => 'select_group_loan_to_approve_independent_payment_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_to_approve_independent_payment'
          },
          {
            :controller => 'member_payments',
            :action => 'list_of_independent_payment'
          }
        ]
      },
      {
        :title => "#{I18n.translate 'process.grace_period_payment'} ",
        :destination_link => 'select_group_loan_for_grace_period_payment_approval_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_grace_period_payment_approval'
          },
          {
            :controller => "transaction_activities", 
            :action => "select_pending_grace_period_payment_to_be_approved"
          }
        ]
      },
      {
        :title => "Default Resolution Execution",
        :destination_link => 'select_group_loan_for_default_resolution_execution_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_default_resolution_execution'
          },
          {
            :controller => "backlog_payments", 
            :action => "select_pending_backlog_to_be_approved"
          }
        ]
      }
      # ,
      # {
      #   :title => "Pengembalian Tabungan",
      #   :destination_link => 'select_group_loan_for_savings_disbursement_start_url',
      #   :conditions => [
      #     {
      #       :controller => 'group_loans',
      #       :action => 'select_group_loan_for_savings_disbursement_start'
      #     } 
      #   ]
      # },
      # {
      #   :title => "Finalisasi Pengembalian Tabungan",
      #   :destination_link => 'select_group_loan_for_savings_disbursement_finalization_url',
      #   :conditions => [
      #     {
      #       :controller => 'group_loans',
      #       :action => 'select_group_loan_for_savings_disbursement_finalization'
      #     } 
      #   ]
      # }
    ]
  }
  
  SAVINGS_PROCESS_LIST ={
    :header_title => "Savings",
    :processes => [
      {
        :title => "#{I18n.t 'process.savings_withdrawal'}",
        :destination_link => "search_member_for_savings_withdrawal_url",
        :conditions => [
          {
            :controller => 'members',
            :action => 'search_member_for_savings_withdrawal'
          },
          {
            :controller => "members",
            :action => 'input_value_for_cash_savings_withdrawal'
          }
        ]
      }
    ]
  }
  
  GROUP_EMPLOYEE_MANAGEMENT_PROCESS_LIST = {
    :header_title => "Group Officer Assignment",
    :processes => [
      {
        :title => "#{I18n.translate 'process.assign_field_worker'}",
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
        :title => "#{I18n.translate 'process.assign_loan_inspector'}",
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
        :title => "#{I18n.translate 'process.finalize_financial_education_attendance'}",
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
        :title => "#{I18n.translate 'process.finalize_loan_disbursement_attendance'}",
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
    :header_title => "FIELD WORKER: Group Loan",
    :processes => [
      {
        :title => "#{I18n.translate 'process.financial_education_attendance' }",
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
        :title => "#{I18n.t 'process.weekly_meeting'}",
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
        :title => "#{I18n.t 'process.weekly_payment'}",
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
          },
          {
            :controller => "weekly_tasks",
            :action => 'edit_transaction_for_member'
          }
        ]
      }, 
      {
        :title => "#{I18n.translate 'process.independent_payment'}",
        :destination_link => "select_group_loan_for_independent_weekly_payment_url",
        :conditions => [
          {
            :controller => "group_loans",
            :action => "select_group_loan_for_independent_weekly_payment"
          },
          {
            :controller => "group_loans",
            :action => "select_member_for_independent_weekly_payment"
          },
          {
            :controller => "member_payments",
            :action => "make_independent_payment"
          },
          {
            :controller => "member_payments",
            :action => "edit_independent_payment"
          }
        ]
      },
      {
        :title => "#{I18n.translate 'process.grace_period_payment'} ",
        :destination_link => "select_group_loan_for_grace_period_payment_url",
        :conditions => [
          {
            :controller => "group_loans",
            :action => 'select_group_loan_for_grace_period_payment'
          },
          {
            :controller => "group_loans",
            :action => "default_members_for_grace_period_payment"
          },
          {
            :controller => "group_loans",
            :action => 'grace_period_payment_calculator'
          },
          {
            :controller => "group_loans",
            :action => 'edit_grace_period_payment_calculator'
          }
        ]
      },
      {
        :title => "#{I18n.translate 'process.loan_default_resolution'}",
        :destination_link => 'select_group_loan_for_loan_default_resolution_url',
        :conditions => [
          {
            :controller => 'group_loans',
            :action => 'select_group_loan_for_loan_default_resolution'
          },
          {
            :controller => "group_loans",
            :action => 'standard_default_resolution_schema'
          },
          {
            :controller => "group_loans",
            :action => 'custom_default_resolution_schema'
          },
          {
            :controller => "default_payments",
            :action => 'payment_for_default_resolution'
          }
        ]
      }
      # ,
      # # gonna be savings disbursement 
      # {
      #   :title => "Pengembalian Tabungan",
      #   :destination_link => 'select_group_loan_to_propose_savings_disbursement_finalization_url',
      #   :conditions => [
      #     {
      #       :controller => 'group_loans',
      #       :action => 'select_group_loan_to_propose_savings_disbursement_finalization'
      #     },
      #     {
      #       :controller => "group_loans",
      #       :action => 'add_details_to_propose_savings_disbursement_finalization'
      #     } 
      #   ]
      # }
    ]
  }
  
  
  
end
