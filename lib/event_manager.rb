require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number.gsub!(/[^0-9]/i,'')
  num_length = number.to_s.length
  if num_length == 10
    number
  elsif num_length == 11 && number.to_s[0] == '1'
    number.to_s[1..9].to_i
  else
    'wrong number!'
  end
end

def best_hour(reg_date)
  date = Time.strptime(reg_date, "%m/%d/%y %k:%M")
  date.hour
end

def best_day(reg_date)
  date = Time.strptime(reg_date, "%m/%d/%y %k:%M")
  case date.wday
  when 0
    "Sunday"
  when 1
    "Monday"
  when 2
    "Tuesday"
  when 3
    "Wednesday"
  when 4
    "Thursday"
  when 5
    "Friday"
  when 6
    "Saturday"
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') { |file| file.puts form_letter }
end

puts 'EventManager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
hours = Hash.new(0)
days = Hash.new(0)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  reg_date = row[:regdate]
  hours[best_hour(reg_date)] += 1
  days[best_day(reg_date)] += 1
  phone = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
end
hours = hours.sort_by {|hour, occurences| occurences}
days = days.sort_by {|day, occurences| occurences}
puts "The hour where more people registered is #{hours[-1][0]}:00"
puts "The day where more people registered is #{days[-1][0]}"
