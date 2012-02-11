# Users controller is made to handle User account created by the admin/super admin

class UsersController < ApplicationController
  def create_employee
    @new_user = User.new(params[:user])
    # assign random_password to password and password_confirmation
    new_password = UUIDTools::UUID.timestamp_create.to_s[0..7]
    @new_user.password = new_password
    @new_user.password_confirmation = new_password
    
    if @new_user.valid? 
      User.create_and_assign_roles( @new_user, params[:role][:role_id])
    end
    
    redirect_to root_url
  end
  
  
  def new_employee
  end
  
  def all_employees
    # @employees = User.all_user_except_role( Role.find_by_name("SuperUser") )
    @employees = User.all 
    @roles = Role.all
  end
  
  def edit_employee
    @employee = User.find_by_username(params[:username])
  end
  
  def update_employee
    @employee = User.find_by_username(params[:username])
    # User.updaet_roles(@employee , params[:role][:role_id])
    @employee.update_roles( params[:role][:role_id].map{|x| x.to_i})
    
    # parse the role, update
    redirect_to edit_employee_url(@employee.username)
  end
end
