require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require "rubygems"
require "httparty"
require "ap"
require 'crack'

Prawn.debug = true
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
  x_pos = ((pdf.bounds.width / 2) - 150) 
  y_pos = ((pdf.bounds.height / 2) + 100) 
  
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
  
  pdf.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
  pdf.font("Hoefler", :style => :normal)
  pdf.font_size 15
  
  response = HTTParty.get("http://#{'ushahidi_url'}/api?task=pi?task=incident&orderfiled=field&sort=1&limit=10")
  
  puts "Dialing: http://#{'ushahidi_url'}/api?task=pi?task=incident&orderfiled=field&sort=1&limit=10"
  
  data = response.body
  result = Crack::JSON.parse(data)
  @incidents = result["payload"]["incidents"]
  
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
  pdf.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
  pdf.font("Hoefler", :style => :normal)
  pdf.font_size 15
  
  if File.exist?('haiti.json.txt')
    # parse the file
    p "reading from the existing file ...."
    jsonfile= File.open("haiti.json.txt", "r")
    results= jsonfile.read
    parsed_results= Crack::JSON.parse(results)
    @incidents = parsed_results['payload']['incidents']
    
    pdf.bounding_box([x_pos, y_pos], :width => 300, :height => 400) do  
      @incidents.each do |i|
        pdf.text i['incident']['incidentdescription']
        pdf.start_new_page
      end    
    end
    jsonfile.close
    pdf.render_file("book.pdf")
    `open book.pdf`
  else
    # write the file
    p "reading directly from instance API ..."  
    response= HTTParty.get("http://haiti.ushahidi.com/api?task=incidents&by=all")
    jsonfile= File.new("haiti.json.txt", "w")
    data = response.body
    puts data
    jsonfile.write(data)
    jsonfile.close
  end  
  

end