require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require 'json'
require "rubygems"
require "httparty"
require 'crack'

INSTANCE= "http://haiti.ushahidi.com/api?task=incidents&by=all"

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
        i['incident']['incidentmedia']
        
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
    
    def read
      p "... reading cache"
      jsonfile= File.open("cache.json", "r")
      results= jsonfile.read
      parsed_results= Crack::JSON.parse(results)
      jsonfile.close
      p "... incidents loaded"
      return parsed_results['payload']['incidents']
    end
  
    def write(data)
      jsonfile= File.new("cache.json", "w")
      jsonfile.write(JSON.pretty_generate(Crack::JSON.parse(data)))
      jsonfile.close
      p "... cache written"
    end
  end

  class Crawler
    def crawl(instance)
      p "crawling around on the web..."
      return HTTParty.get(INSTANCE).body
      # read the id of the last item
      # be nice
      # sleep 1
      # start another query from where we left off
      # remove duplicates
    end
  end
end

book= PrintingPress::Book.new
crawler=PrintingPress::Crawler.new
cache=PrintingPress::Cache.new

unless cache.full?
  cache.write(crawler.crawl(INSTANCE))
end

book.bind(cache.read)
p "printing!"
book.print
