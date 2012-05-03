require 'spec_helper'

describe Office do
  
  context "subdistrict allocation" do
    it "should not have overlapping subdistricts with another office"
  end
  
  context "user/employee registration" do 
    it "will not create user if the user's particular is invalid" 
    it "should create user with the given role list " 
    it "should not have overlapping office with another" 
  end
  
  context "member registration" do
    it "can only create member whose address is in this office's subdistrict"
  end
end