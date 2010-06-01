require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require 'json'
require "rubygems"
require "httparty"
require 'crack'
require 'ostruct'
require 'ap'

INSTANCE_URL= "http://haiti.ushahidi.com/api?task=incidents&by=sinceid&resp=json&id="
# INSTANCE_URL= "http://roguegenius.com/africa/api?task=incidents&by=sinceid&resp=json&id="

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


def clean(incidents)
  incidents.each do |i|
    p i["#{incidentid},"]
  end
end

def fill_cache
  book= PrintingPress::Book.new
  crawler= PrintingPress::Crawler.new  
  cache= PrintingPress::Cache.new
  sinceid=0
  until sinceid > 5000 do
    # construct the url with sinceid
    theurl= "#{INSTANCE_URL}#{sinceid}"
    incidents= crawler.crawl(theurl)
    incidents.each do |json|
      cache.write(json)
    end
    sleep 2
    sinceid += incidents.last["incident"]["incidentid"].to_i
  end
end

def filter_data(incidents)
  p "#{incidents.count} before uniq"
  p "uniqifying"
  filtered_incidents= incidents.uniq
  p "#{incidents.count} after uniq"
  return filtered_incidents
end
  
if ARGV[0] = "cache"
  cache= PrintingPress::Cache.new
  if cache.full?
    p "looks like your cache has data -- try deleting it first."
  else
    fill_cache
  end
elsif ARGV[0] = "filter"
  incidents = cache.read
  filter_data(incidents)
elsif ARGV[0] = "print"
  book.print(cache.read)
else
  p "usage: ruby ushahidi2pdf.rb [cache|filter|print]"
end
