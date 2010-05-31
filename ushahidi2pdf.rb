require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require 'json'
require "rubygems"
require "httparty"
require 'crack'

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
  
    def bind(incidents)
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
        @book.start_new_page
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
  
    def write(data, filename= "cache.json")
      jsonfile= File.new(filename, "w")
      jsonfile.write(JSON.pretty_generate(Crack::JSON.parse(data)))
      jsonfile.close
      p "... cache written"
    end
  end

  class Crawler

    def initialize
      attr_accessor :sinceid
      @sinceid= 0
    end
              
    # start at the first one
    def start(current_id= "0", prev_id= "null")
      #stop automatically when you get the same record twice
      while @sinceid != prev_sinceid
        instance= "#{INSTANCE_URL}#{sinceid}"
        p "off to #{instance}"
        crawled_pages= []
        crawled_pages.push("instance")
        p "Crawled pages is now #{crawled_pages.inspect}"
        data= HTTParty.get(instance).body
        parsed_data= Crack::JSON.parse(data)
        last_one= parsed.data[payload][incidents].last
        p "the last incident is #{last_one.inspect}"
        p "completed lookup to record #{prev_sinceid}"
        return last_one[incidentid], prev_sinceid
      end
    end
  end
end

book= PrintingPress::Book.new
crawler= PrintingPress::Crawler.new
cache= PrintingPress::Cache.new

unless cache.full?
  cache.write(crawler.start)
end

book.bind(cache.read)
p "printing!"
book.print
