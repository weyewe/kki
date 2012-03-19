class Assignment < ActiveRecord::Base
  belongs_to :job_attachment 
  belongs_to :role
end
