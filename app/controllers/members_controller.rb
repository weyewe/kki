class MembersController < ApplicationController
  def new
    setup_members
    @new_member = Member.new 
    
  end
  
  def create
    setup_members
    @new_member = Member.new( params[:member])
    @new_member.creator_id  = current_user.id 
    @new_member.office_id = @office.id 
    
    if @new_member.save
      flash[:notice] = "The new member has been created." + 
                    " To see the list, click <a href='#data_list'>here</a>."
      redirect_to new_member_url 
    else
      flash[:error] = "Hey, do something better"
      render :file => "members/new"
    end
    
  end
  
  protected
  def setup_members
    @office = current_user.active_job_attachment.office
    @office_members = @office.members
    @all_communes = @office.all_communes_under_management
  end
end
