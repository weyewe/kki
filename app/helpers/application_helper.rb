module ApplicationHelper
  ACTIVE = 'active'
  
  
  #######################################################
  #####
  #####     For the process-navigation active state
  #####
  #######################################################
  
  def get_active_state( section , params )
    
     if section == ADMIN_SECTION[:create_employee]  
        if selected_create_employee_tab?(params)
          return ACTIVE
        end
      end
      
      
    if section == ADMIN_SECTION[:all_employees] or section == ADMIN_SECTION[:edit_employee]
      if   selected_all_employees_tab?(params) or 
          selected_edit_employee_tab?(params)
        return ACTIVE
      end
    end
    
   
  end
  
  
  
  
  protected
  
  #######################################################
  #####
  #####     For the process-navigation active state
  #####       , protected method to check the selected tab
  #####
  #######################################################
  

  def selected_create_employee_tab?(params)
     if params[:controller] == "users" && params[:action] == "new_employee"
       return true
     end

     return false
   end
  
  
  
  
  def selected_all_employees_tab?(params)
    if params[:controller] == "users" && params[:action] == "all_employees" 
      return true
    end

    return false
    
  end
  
  def selected_edit_employee_tab?(params)
    if  params[:controller] == "users" && params[:action] == "edit_employee"  
      return true
    end

    return false
  end
  
  
 
  
  
  
end
