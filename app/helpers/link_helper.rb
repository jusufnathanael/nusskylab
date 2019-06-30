
require 'net/http'
require 'uri'
require 'open-uri'

def is_valid_image_url?(url)
  og_url = url
  puts url
  puts "\n"
  url = URI(url)
  # url = URI.parse(url)
  # http = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https')
  # out =  http.head(url.request_uri)
  # out =  get(url)
  # out = http.get_response(url)
  # contents = open(or_url) {|f| f.read }
  # puts contents
  out = Net::HTTP.get(url)
  http = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https')
  out = http.head(url.request_uri)
  puts out['Content-Type']
  puts "yeeta skeeta"
  print_dict(out)
  # puts out.body
  if out['Content-Type'].to_s.include? 'text/html' then
    puts "YEEEEEEEEEEEEEEEEEEEEEEEEEt"
    raw_url = out['location']
    puts raw_url
    url = URI(raw_url)
    http = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https')
    out = http.head(url.request_uri)
    print_dict(out)
    out = Net::HTTP.get(url)
    print out
    # out = Net::HTTP.get_response(url)
    # print_dict(out)
    # puts out
    # out = Net::HTTP.get(url)
    
    # puts out
    # out.each do |key, value|
      # puts key.to_s + ':' + value
    # end
    # out = http.get_response(url)
    # puts out
    # print_dict(out)
    # print_dict(out)
  end
end

def is_direct_image_link?(url, image_extensions=['jpeg', 'jpg', 'png'])
  url = URI(url)
  http = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https')
  res_header = http.head(url.request_uri)
  
  is_image = false
  for image_extension in image_extensions do
    header_checker = "image/#{image_extension}"
    contains_checker = res_header['Content-Type'].to_s.include? header_checker
    is_image = is_image || contains_checker
  end
  return is_image
end  

def print_dict(dict_to_print)
  dict_to_print.each do |key, value|
    puts key.to_s + ' : ' + value
  end
end

def is_google_drive_link?(url)
  gdrive_prefix = "https://drive.google.com/"
  is_gdrive_link = url[0..gdrive_prefix.length - 1] == gdrive_prefix
  return is_gdrive_link
end

def get_google_drive_view_link(url)
  raise "not a google drive link" unless is_google_drive_link? url
  gdrive_id = url.to_s.scan(/id=.*/)[0].to_s
  if gdrive_id.include? "&"
    gdrive_id = (gdrive_id.split('&'))[0]
    gdrive_id = gdrive_id.to_s.scan(/id=.*/)[0].to_s
  end
  
  gdrive_view_link = "https://drive.google.com/uc?#{gdrive_id}&export=view"
  puts gdrive_view_link
  return gdrive_view_link
end

test_url = "https://www.smashbros.com/images/og/link.jpg"
# test_url = "https://drive.google.com/open?id=12gYWVnvY_A0v66hY-9zFQMzoZ-j4Tsqf"
# is_google_drive_link? test_url
test_url = 'https://drive.google.com/open?id=12gYWVnvY_A0v66hY-9zFQMzoZ-j4Tsqf'
# test_url = 'https://drive.google.com/uc?id=12gYWVnvY_A0v66hY-9zFQMzoZ-j4Tsqf&export=view'
# is_valid_image_url?(test_url)

# is_direct_image_link? test_url  
# is_google_drive_link? test_url
get_google_drive_view_link(test_url)
