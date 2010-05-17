require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require "rubygems"
require "httparty"
require 'pp'
require 'crack'

Prawn.debug = true
pdf = Prawn::Document.new(:page_layout => :landscape)
 
unless ARGV.length == 1
  puts "CSV Usage: ruby ushahidi2pdf.rb your_ushahidi_export_file.csv \n"
  puts "API Usage: ruby ushahidi2pdf.rb your.instance.domain.com"
  exit
end

def setup_fonts
  pdf.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
  pdf.font("Hoefler", :style => :normal)
  pdf.font_size 15
end

if ARGV[0] = /.csv$/
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
else
  p "reading instance API ..."
  ushahidi_url = ARGV[1]
  setup_fonts
  response = HTTParty.get("http://#{'ushahidi_url'}/api?task=incidents&by=all")
  data = response.body
  result = Crack::JSON.parse(data)
  @incidents = result["payload"]["incidents"]
  
  pdf.bounding_box([x_pos, y_pos], :width => 300, :height => 400) do  
    @incidents.each do |incident|
      pdf.text incident['incidenttitle']
      pdf.start_new_page
    end    
  end

  pdf.render_file("book.pdf")
end