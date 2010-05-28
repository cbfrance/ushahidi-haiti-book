require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require "rubygems"
require "httparty"
require "ap"
require 'crack'

# config
instance_address= "http://haiti.ushahidi.com/api?task=incidents&by=all"
Prawn.debug = true
font_family= "Hoefler" => { :normal => "Hoefler Text.dfont" }
pdf = Prawn::Document.new(:page_layout => :landscape)
 
unless ARGV.length == 1
  puts "CSV Usage: ruby ushahidi2pdf.rb your_ushahidi_export_file.csv \n"
  puts "API Usage: ruby ushahidi2pdf.rb your.instance.domain.com"
  exit
end

puts ARGV[0]

if ARGV[0] =~ /.csv$/
  p "reading csv ..."
  input_file = ARGV[0]
  
  #typesetting
  pdf.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
  pdf.font("Hoefler", :style => :normal)
  pdf.font_size 15
  x_pos = ((pdf.bounds.width / 2) - 150) 
  y_pos = ((pdf.bounds.height / 2) + 100) 
  
  # draw a box and spit in each record (this expects the csv to be just the incidents)
  pdf.bounding_box([x_pos, y_pos], :width => 300, :height => 400) do  
    f = File.open(input_file, "r")
    f.each_line { |line|
      words = line.split('%t')
      if words[0].tr_s('"', '').strip != ""
        pdf.text(words[0].tr_s('"', '').strip.capitalize)
      end
      pdf.start_new_page
    }
  end 

elsif ARGV[0] =~ /.json$/ 
  p "reading from local json file ..."
  
  #typesetting
  pdf.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
  pdf.font("Hoefler", :style => :normal)
  pdf.font_size 15
  x_pos = ((pdf.bounds.width / 2) - 150) 
  y_pos = ((pdf.bounds.height / 2) + 100) 
  
  #carve out the incidents from the response
  response = HTTParty.get("http://#{'ushahidi_url'}/api?task=pi?task=incident&orderfiled=field&sort=1&limit=10")  
  data = response.body
  result = Crack::JSON.parse(data)
  @incidents = result["payload"]["incidents"]
  
  #draw a box, insert the incident, create a new page
  pdf.bounding_box([x_pos, y_pos], :width => 300, :height => 400) do  
    @incidents.each do |incident|
      pdf.text incident['incidenttitle']
      pdf.start_new_page
    end
  end

# ============
# = API CALL =
# ============  
else

  #typesetting
  x_pos = ((pdf.bounds.width / 2) - 150) 
  y_pos = ((pdf.bounds.height / 2) + 100) 
  pdf.font_families.update(font_family)
  pdf.font("Hoefler", :style => :normal)
  pdf.font_size 15
  
  #check the cache
  if File.exist?('haiti.json.txt')
    # parse the cache
    p "reading from the existing file ...."
    jsonfile= File.open("haiti.json.txt", "r")
    results= jsonfile.read
    parsed_results= Crack::JSON.parse(results)
    jsonfile.close
    @incidents = parsed_results['payload']['incidents']

    #draw the box, add reports
    pdf.bounding_box([x_pos, y_pos], :width => 300, :height => 400) do  
      @incidents.each do |i|
        pdf.text i['incident']['incidentdescription']
        pdf.start_new_page
      end    
    end
    
    #off to the printers
    pdf.render_file("book.pdf")
    `open book.pdf`
  else
    # read the api
    
    p "reading directly from instance API ..."  
    response= HTTParty.get(instance_address)
    jsonfile= File.new("haiti.json.txt", "w")
    data = response.body
    puts data
    jsonfile.write(data)
    jsonfile.close
  end
end