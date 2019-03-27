require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4] 
end

def parse_datestring(date_string)
  reg_date = DateTime.strptime(date_string, "%m/%d/%Y %H:%M")
  reg_date = DateTime.new(2000 + reg_date.year, reg_date.month,
                          reg_date.day, reg_date.hour, reg_date.minute)
  reg_date
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

  unless File.open(filename).read == form_letter
    File.open(filename, 'w') do |f|
      f.write form_letter
    end
  else
    puts " [WARNING] Letter for ID:#{id} already exists!"
  end
end

def find_best_day(dts)
  days = Hash.new(0)
  dts.each do |date|
    day_of_week = date.strftime("%A") # Get the name of the day
    days[day_of_week] += 1
  end

  best_day = {:day => "", :count => 0}
  # Find the day with most registration count
  days.each do |day, count|
    if count > best_day[:count]
      best_day[:day] = day
      best_day[:count] = count
    else
      next
    end
  end

  puts "THE MOST POPULAR DAY IS #{best_day[:day].upcase} with #{best_day[:count]} regs."
end

puts "EventManager Initialized!"
contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
reg_dts = []
clean_phone_numbers = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  clean_phone_numbers << clean_phone(row[:homephone])

  reg_date = parse_datestring(row[:regdate])
  reg_dts << reg_date
  save_thank_you_lettters(id, form_letter)
  
  puts "Saving Thank You letters (id: #{id}). Please wait..."
end

find_best_day(reg_dts)

