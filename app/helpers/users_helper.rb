module UsersHelper
  ACTIVE = 'active'
  
  #######################################################
  #####
  #####     User listing and edit navigation 
  #####
  #######################################################
  
  def get_user_nav_active_state( section , params )

    if section == USER_NAV[:list_employees]  
      if selected_list_employees_tab?(params)
        return ACTIVE
      end
    end

    if section == USER_NAV[:edit_employee]  
      if  selected_edit_employee_tab?(params)
        return ACTIVE
      end
    end

  end

  
  protected
  
  #######################################################
  #####
  #####     User listing and edit navigation 
  #####
  #######################################################
  
  def selected_list_employees_tab?(params)
    if params[:controller]=="users" && params[:action]=="all_employees"
      return true
    end
    
    return false
  end
  
  def selected_edit_employee_tab?(params)
    if params[:controller]=="users" && params[:action]=="edit_employee"
      return true
    end
    
    return false
  end
  
end
