require 'rubygems'
$LOAD_PATH.unshift("/Users/davidnolen/development/ruby/prawn/lib")
require 'prawn'
require 'json'
require "rubygems"
require "httparty"
#require "ap"
require 'crack'

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
    @format= ARGV[0]
  end
  def parse(format = "json")
    jsonfile= File.open("cache.json", "r")
    results= jsonfile.read
    parsed_results= Crack::JSON.parse(results)
    jsonfile.close
    @incidents = parsed_results['payload']['incidents']
  end
    
  def full?
    File.exist?("cache.json")
  end
   
    
  def fill_from_url
    p "reading instance API ..."  
    instance_address= "http://haiti.ushahidi.com/api?task=incidents&by=all"
    response= HTTParty.get(instance_address)
    jsonfile= File.new("cache.json", "w")
    p "Saving yaml"
    yamlfile= jsonfile.to_yaml
    p yamlfile
    p "success"
    data = response.body
    puts data
    jsonfile.write(JSON.pretty_generate(Crack::JSON.parse(data)))

    puts "cache written"
    jsonfile.close
  end
end


# ==================
# = printing press =
# ==================

book=Book.new
cache=Cache.new
if cache.full?
  texts= cache.parse("json")
  # book.bind(texts)
  p "binding"
  # book.print
  p "printing"
else
  cache.fill_from_url
end
