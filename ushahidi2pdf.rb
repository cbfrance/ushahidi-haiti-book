require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require "rubygems"
require "httparty"
require "ap"
require 'crack'

# config
instance_address= "http://haiti.ushahidi.com/api?task=incidents&by=all"

class Book
  def initialize
    @pdf = Prawn::Document.new(:page_layout => :landscape)
    Prawn.debug = true
  end
  def typeset
    @pdf.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
    @pdf.font("Hoefler", :style => :normal)
    @pdf.font_size 15    
    @x_pos = ((@pdf.bounds.width / 2) - 150) 
    @y_pos = ((@pdf.bounds.height / 2) + 100)
  end
  def bind(texts)
    self.typeset
    #draw the box, add reports
    @pdf.bounding_box([@x_pos, @y_pos], :width => 300, :height => 400) do  
      texts.each do |i|
        @pdf.text i['incident']['incidentdescription']
        @pdf.start_new_page
      end    
    end
  end
  def print
    @pdf.render_file("book.pdf")
    `open book.pdf`
  end
end

class Cache
  def initalize
    format= ARGV[0]
  end
  def parse(format)
    if format =~ /.json$/
      jsonfile= File.open("cache.txt", "r")
      results= jsonfile.read
      parsed_results= Crack::JSON.parse(results)
      jsonfile.close
      @incidents = parsed_results['payload']['incidents']
    elsif(format =~ /.csv$/ )
      filename = ARGV[0]

      @pdf.bounding_box([@x_pos, @y_pos], :width => 300, :height => 400) do  
        csv = File.open(filename, "r")        
        f.each_line { |line|
          words = line.split('%t')
          if words[0].tr_s('"', '').strip != ""
            pdf.text(words[0].tr_s('"', '').strip.capitalize)
          end
          pdf.start_new_page
        }
      end
    end
    
  end
    
  end
  def full?
    File.exist?("cache.txt")
  end
  def fill_from_url
    p "reading instance API ..."  
    response= HTTParty.get(instance_address)
    jsonfile= File.new("cache.txt", "w")
    data = response.body
    puts data
    jsonfile.write(data)
    jsonfile.close
  end
  def fill_from_csv
    
  end
end


# ==================
# = printing press =
# ==================

book=Book.new
cache=Cache.new

if ARGV[0] =~ /.csv$/
  book.typeset  
  cache.fill_from_csv
  cache.parse_csv
  
elsif ARGV[0] =~ /.json$/ 
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
  if cache.full?
    text= cache.parse_json
    book.bind(texts)
    book.print
  else
    cache.fill_from_url
  end
end