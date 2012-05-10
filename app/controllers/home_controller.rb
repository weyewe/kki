class HomeController < ApplicationController
  # skip_filter :authenticate_user!, :only => [ :dashboard]
  skip_filter :authenticate_user!, :only => [ :raise_exception]
  
  def dashboard
  
    
  end
  
  def raise_exception  
    puts 'I am before the raise.'  
    raise 'An error has occured'  
    puts 'I am after the raise'  
  end
  
  
  
end
