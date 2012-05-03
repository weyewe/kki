class Assignment < ActiveRecord::Base
  belongs_to :job_attachment 
  belongs_to :role
  
  # before_create :cancel_creation_if_such_role_assignment_exists
  
  
  def Assignment.create_role_assignment_if_not_exists( role,  user )
    assignments_count = Assignment.find(:all, :conditions => {
      :role_id => role.id,
      :job_attachment_id =>user.get_active_job_attachment.id 
    }).count
    
    if assignments_count == 0 
      Assignment.create(:job_attachment_id => user.get_active_job_attachment.id , :role_id => role.id)
    end
  end
 
  
end
