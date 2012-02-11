class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :username, :email, :password, :password_confirmation, :remember_me
  attr_accessor :login
  
  # Models
  has_many :assignments
  has_many :roles, :through => :assignments
  
  
  # validation
  validates_presence_of :username
  validates_uniqueness_of :username
  validates_confirmation_of :password , :message => "Password doesn't match password confirmation"
    
  
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
   
   
  
  
  def has_role?(role_sym)
    roles.any? { |r| r.name.underscore.to_sym == role_sym }
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
