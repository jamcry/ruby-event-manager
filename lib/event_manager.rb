require "csv"
require "google/apis/civicinfo_v2"
require "erb"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4] 
end

def clean_phone(phone_number)
  number = phone_number.gsub(/\D/, '') # delete non digit chars
  len = number.length
  if len < 10
    number = nil
  elsif len == 10
    number = number
  elsif len == 11 && number[0] == "1"
    number = number[1..] # trim the 1 at the beginning
  else
   number = nil
  end

  if number
    number = number[0..2] + "-" + number[3..5] + "-" + number[6..]
  end
  number
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
				                          address: zip,
				                          levels: "country",
				                          roles: ["legislatorUpperBody", "legislatorLowerBody"]).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_lettters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")
  
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |f|
    f.puts form_letter
  end
end

puts "EventManager Initialized!"
contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  #id = row[0]
  #name = row[:first_name]
  #zipcode = clean_zipcode(row[:zipcode])
  
  #legislators = legislators_by_zipcode(zipcode)

  #form_letter = erb_template.result(binding)
  puts clean_phone(row[:homephone])
  #save_thank_you_lettters(id, form_letter)
end

