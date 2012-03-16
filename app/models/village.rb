class Village < ActiveRecord::Base
  belongs_to :subdistrict
  has_many :communes
end
