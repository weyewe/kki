class Role < ActiveRecord::Base
  has_many :assignments
  has_many :job_attachments, :through => :assignments
end
