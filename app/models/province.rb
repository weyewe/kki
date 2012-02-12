class Province < ActiveRecord::Base
  has_many :regencies
  belongs_to :island
end
