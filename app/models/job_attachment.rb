class JobAttachment < ActiveRecord::Base
  belongs_to :user
  belongs_to :office 
  
  # The role sticks on the job_attachment, not the user
  # it means, a user can be a Branch Manager in Cilincing, but just
  #  a field_worker in other places 
  has_many :assignments
  has_many :roles, :through => :assignments
  
  
  def has_role?(role_sym)
    roles.any? { |r| r.name.underscore.to_sym == role_sym }
  end
  
  
  def group_loan_products
    self.office.group_loan_products
  end
end
