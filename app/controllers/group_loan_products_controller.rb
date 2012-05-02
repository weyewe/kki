class GroupLoanProductsController < ApplicationController
  def new
    setup_group_loan_products
    
    @new_group_loan_product = GroupLoanProduct.new 
  end
  
  def create
    setup_group_loan_products
    
    @new_group_loan_product = GroupLoanProduct.new(params[:group_loan_product])
    @new_group_loan_product.office_id  = @office.id 
    
    # @new_group_loan_product = GroupLoanProduct.create_by_branch_manager( 
    #               params[:group_loan_product] , current_user )
    
    if @new_group_loan_product.save
      flash[:notice] = "The new group loan product has been created." + 
                    " To see the list, click <a href='#data_list'>here</a>."
      redirect_to new_group_loan_product_url 
    else
      flash[:error] = "Hey, do something better"
      render :file => "group_loan_products/new"
    end
    
  end
  
  
  protected
  def setup_group_loan_products
    @group_loan_products = current_user.active_job_attachment.group_loan_products
    @office = current_user.active_job_attachment.office
  end
  
  
end
