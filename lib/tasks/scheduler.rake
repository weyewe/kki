desc "This task is called by the Heroku cron add-on"
task :call_page => :environment do
  uri = URI.parse('http://www.kkims.com/')
  Net::HTTP.get(uri)
  puts "this is it"
end


task :parse_uni => :environment do
  # // Open the file with fast csv 
  # Create the user. for those Failed user , save it into the failed user db
  uri = URI.parse('http://www.potoschool.com/')
  Net::HTTP.get(uri)
  puts "this is it"
end




