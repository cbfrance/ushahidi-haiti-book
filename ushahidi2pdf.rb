require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require 'json'
require "rubygems"
require "httparty"
require 'crack'
require 'ostruct'
require 'ap'

# INSTANCE= "http://haiti.ushahidi.com/api?task=incidents&by=all"
INSTANCE_URL= "http://roguegenius.com/africa/api?task=incidents&by=sinceid&resp=json&id="

module PrintingPress
  class Book
    def initialize
      @book = Prawn::Document.new
      Prawn.debug = true
      @x_pos = ((@book.bounds.width / 2) - 150) 
      @y_pos = ((@book.bounds.height / 2) + 200)
      
    end
    def typeset_header
      @book.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
      @book.font("Hoefler", :style => :normal)
      @book.font_size 15
    end
  
    def typeset_date
      @book.font_size 10
      @book.font("Courier")
    end
  
    def typeset_latlong
      @book.font_size 6
    end
  
    def write(incidents)
      typeset_date
      #draw the box, add reports
      incidents.each do |i|
        @book.bounding_box([@x_pos, @y_pos], :width => 300, :height => 500) do  
          @book.text((i['incident']['incidenttitle']))
          @book.text("--------------------------------------------------")
          @book.text((i['incident']['incidentdescription']).gsub(/IDUshahidi:\W+\d+/, ''))
        end
        @book.text(i['incident']['incidentmedia'])
        @book.text(i['incident']['incidentdate'])
        @book.text(i['incident']['locationlatitude'])
        @book.text(i['incident']['locationlongitude'])
        @book.start_new_IncidentCount
      end
    end
    def print
      @book.render_file("book.pdf")
      `open book.pdf`
    end
  end

  class Cache
    def full?
      File.exist?("cache.json")
    end
    
    def read(filename="cache.json")
      p "... reading cache"
      jsonfile= File.open(filename, "r")
      results= jsonfile.read
      parsed_results= Crack::JSON.parse(results)
      jsonfile.close
      p "... incidents loaded"
      return parsed_results['payload']['incidents']
    end
  
    def write(json, filename= "cache.json")
      if File.exists?(filename)
        jsonfile=File.open(filename, "a")
      else
        jsonfile= File.new(filename, "w")
      end
      jsonfile.write(JSON.pretty_generate(json))
      jsonfile.close
      p "... cache written"
    end
  end

  class Crawler
    def crawl(url)
      p "starting to crawl: #{url}"
      data= HTTParty.get(url).body
      parsed_data= Crack::JSON.parse(data)
      @incidents= parsed_data["payload"]["incidents"]
      return @incidents
    end
  end
end

# book= PrintingPress::Book.new
crawler= PrintingPress::Crawler.new
cache= PrintingPress::Cache.new

sinceid=0
until sinceid > 5000 do
  # construct the url with sinceid
  theurl= "#{INSTANCE_URL}#{sinceid}"
  crawler.crawl(theurl).each do |json|
    cache.write(json)
  end
  sinceid += 10000
  # parse the results into a struct
  # result_count = the largest incident id
  # sinceid += result_count
end





