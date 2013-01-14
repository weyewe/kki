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
    
    @new_member.save
    @has_no_errors  = @new_member.errors.messages.length == 0
    
    
    respond_to do |format|
      format.html  do
        if @has_no_errors == true 
          flash[:notice] = "The new member has been created." + 
                        " To see the list, click <a href='#data_list'>here</a>."
          redirect_to new_member_url 
        else
          flash[:error] = "Hey, do something better"
          render :file => "members/new"
        end
      end
      
      
      format.js  do 
      end
    end 
  end
  
  
  
  def edit
    
    setup_members
    @member = Member.find_by_id params[:id]
  end
  
  def update_member
    setup_members
    @member = Member.find_by_id params[:member_id]
    
    @member.update_attributes(params[:member])
    @has_no_errors  = @member.errors.messages.length == 0
  end
=begin
  Savings Withdrawal, hard cash 
=end
  def search_member_for_savings_withdrawal
    @office = current_user.active_job_attachment.office
    @members = [] 
    if not  params[:member_name].nil?  and not params[:member_name].length == 0 
      name_query = '%' + params[:member_name] + '%'
      office = @office
      @members = Member.where{ (name =~ name_query) & {office_id => office.id} }
    end
    
    respond_to do |f|
      f.html do
         add_breadcrumb "#{t 'process.select_group_loan'}", 'search_member_for_savings_withdrawal_url'
      end
      
      f.js do 
        @objects  = @members.map{|x| {:name => x.name, :id => x.id }}
        render :json => @objects 
      end
    end
   
  end
  
  def search_member_for_savings
    @office = current_user.active_job_attachment.office
    @members = [] 
    
    name_query = '%' + params[:q] + '%'
    office = @office
    @members = Member.where{ (name =~ name_query) & {office_id => office.id} }.map{|x| {:name => x.name, :id => x.id }}

    render :json => @members  
  end
  
  def input_value_for_cash_savings_withdrawal
    @office = current_user.active_job_attachment.office
    @member = Member.find_by_id params[:member_id]
    @transaction_activities = TransactionActivity.where(
                  :member_id => @member.id, 
                  :transaction_case => TRANSACTION_CASE[:cash_savings_withdrawal]
                  )
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'search_member_for_savings_withdrawal_url'
    set_breadcrumb_for @member, 'input_value_for_cash_savings_withdrawal_url' + "(#{@member.id})", 
                "Amount for Savings Withdrawal"
  end
  
  protected
  def setup_members
    @office = current_user.active_job_attachment.office
    @office_members = @office.members.order("created_at ASC")
    @all_communes = @office.all_communes_under_management
  end
end
