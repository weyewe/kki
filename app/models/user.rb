class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :username, :email, :password, :password_confirmation, :remember_me# ,
  #                 :office_id 
                # we don't need office id over here. wrong assignment 
                
  attr_accessor :login
  
  # The employee can be a manager in one office, and a cashier in another office. 
  # it is all depends on the situation. Fuck. wrong  allocation 
  # has_many :assignments
  #   has_many :roles, :through => :assignments

  validates_confirmation_of :password , :message => "Password doesn't match password confirmation"
  
# An employee can belong to many offices
  has_many :offices, :through => :job_attachments 
  has_many :job_attachments 
  
  
=begin
  FOR BRANCH_MANAGER 
  For any group_loan creation, it has to be tracked as history 
    Newsfeed style ? Good enough 
=end  
    # has_many :group_loans
    
    
    
    
=begin
  FOR Branch Manager
=end
  def get_managed_office
    self.schools.first 
  end
    
    
=begin
  FOR LOAN OFFICER 
=end  
   def assign_group_loan_product( group,  group_loan_product  )
     group.loan_assignment_creator_id = self.id 
     group.group_loan_id = group_loan_product.id
     group.save
   end
   
   
   
       
=begin
    FOR CASHIER 
    approval, only on the group scale. Prevent redundancy.
    The risk of the details payment is on the field_worker
    Cashier only needs to know about the group performance 
=end 

  def approve_deposit( group )
  end
  
  def approve_initial_savings( group )
  end
  
  def approve_admin_fee( group )
  end
    
    
  
    
  
  def User.create_and_assign_roles( new_user, role_id_array)
    for role_id in role_id_array
      role = Role.find_by_id( role_id.to_i )
      new_user.roles << role 
    end
    
    new_user.save
  end
  
  
  def update_roles( new_role_id_array )
    current_role_id_array = Assignment.find(:all, :conditions => {
      :user_id => self.id
    }).collect{ |x| x.role_id }
    
    role_to_be_destroyed  = current_role_id_array - new_role_id_array
    role_to_be_created    = new_role_id_array   - current_role_id_array
    
    role_to_be_destroyed.each do |x|
      Assignment.find(:first, :conditions => {
        :role_id => x, :user_id => self.id
      }).destroy 
    end
    
    role_to_be_created.each do |x|
      Assignment.create :role_id => x , :user_id  => self.id
    end
    
  end
  

  def User.all_user_except_role( role  )
    
  end
   
   
   
  def active_job_attachment
    active_job_attachment = self.job_attachments.where(:is_active => true).first
  end
  
  
  def has_role?(role_sym,  active_job_attachment )
    # job_attachment = JobAttachment.find(:first, :conditions => {
    #      :office_id => office.id , 
    #      :user_id => self.id 
    #    })
    
    active_job_attachment.has_role?(role_sym)
    # roles.any? { |r| r.name.underscore.to_sym == role_sym }
  end
  
  
    
  
  
  def get_active_job_attachment
    self.job_attachments.where(:is_active => true).first
  end
  
  
  
  
  protected
  def self.find_for_database_authentication(conditions)
       login = conditions.delete(:login)
       where(conditions).where({:username => login} | { :email => login}).first
     end
   
     def self.find_or_initialize_with_errors(required_attributes, attributes, error=:invalid)
       case_insensitive_keys.each { |k| attributes[k].try(:downcase!) }
   
       attributes = attributes.slice(*required_attributes)
       attributes.delete_if { |key, value| value.blank? }
   
       if attributes.size == required_attributes.size
         if attributes.has_key?(:login)
           login = attributes.delete(:login)
           record = find_record(login)
         else
           record = where(attributes).first
         end
       end
   
       unless record
         record = new
   
         required_attributes.each do |key|
           value = attributes[key]
           record.send("#{key}=", value)
           record.errors.add(key, value.present? ? error : :blank)
         end
       end
       record
     end
   
     def self.find_record(login)
       where({:username => login} | { :email => login}).first
     end
end
