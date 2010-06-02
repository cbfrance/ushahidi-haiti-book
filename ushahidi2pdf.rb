require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'
require 'json'
require "rubygems"
require "httparty"
require 'crack'
require 'ostruct'
require 'ap'

# INSTANCE_URL= "http://haiti.ushahidi.com/api?task=incidents&by=sinceid&resp=json&id="
INSTANCE_URL= "http://roguegenius.com/africa/api?task=incidents&by=sinceid&resp=json&id="

module PrintingPress

# ========
# = book =
# ========

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
  
    def print(incidents)
      typeset_date
      incidents.each do |i|
        p "printing! This incident: #{i.inspect}"
        if i.empty? 
            p "last one!"
            p "done rendering, now printing for reals!"
            @book.render_file("book.pdf")
            `open book.pdf`
        else
          @book.bounding_box([@x_pos, @y_pos], :width => 300, :height => 500) do  
            @book.text((i['incident']['incidenttitle']))
            @book.text("--------------------------------------------------")
            @book.text((i['incident']['incidentdescription']).gsub(/IDUshahidi:\W+\d+/, ''))
          end
          @book.text(i['incident']['incidentmedia']) unless i['incident']['incidentmedia'] == nil
          @book.text(i['incident']['incidentdate']) unless i['incident']['incidentdate'] == nil
          @book.text(i['incident']['locationlatitude']) unless i['incident']['incidentlatitude'] == nil
          @book.text(i['incident']['locationlongitude']) unless i['incident']['incidentlongitude'] == nil
        end
      end
    end
  end

# =========
# = cache =
# =========

  class Cache
    def full?
      File.exist?("cache.json")
    end

    def read(filename="cache.json")
      p "... reading cache"
      jsonfile= File.open(filename, "r")
      results= jsonfile.read
      p "about to parse!"
      parsed_results= Crack::JSON.parse(results)
      jsonfile.close
      p "... incidents loaded"
      incidents= parsed_results['incidents']
      return incidents
    end
  
    def discover_file(filename)
      if File.exists?(filename)
        jsonfile=File.open(filename, "a")
      else
        jsonfile= File.new(filename, "w")
      end
      return jsonfile
    end
    
    def write_json(data, filename= "cache.json")
      #writes one page at a time to a file, fill_cache wraps this.
      jsonfile= discover_file(filename)
      jsonfile.write(JSON.pretty_generate(data))
      jsonfile.write(",")
      jsonfile.close
      p "... cache written"
    end
    def write_text(text, filename= "cache.json")
      jsonfile= discover_file(filename)      
      jsonfile.write(text)
      jsonfile.close
    end
    
  end

# ===========
# = crawler =
# ===========

  class Crawler
    def crawl(url)
      p "starting to crawl: #{url}"
      data= HTTParty.get(url).body
      parsed_data= Crack::JSON.parse(data)
      @incidents= parsed_data["payload"]["incidents"]
      return @incidents
    end
  end

# ==========
# = worker =
# ==========

  class Worker
    def fill_cache
      crawler= PrintingPress::Crawler.new  
      cache= PrintingPress::Cache.new
      sinceid=0
      cache.write_text('{"incidents":[')
      limit= 48
      until sinceid > limit do
        # incrementing sinceid to work around API limits
        theurl= "#{INSTANCE_URL}#{sinceid}"
        incidents= crawler.crawl(theurl)
        incidents.each do |json|
          prev_json ||= "none"
          #write the json incident record unless it's the same as the last one
          cache.write_json(json)
          # increment the filter trap
          prev_json= json
          p prev_json
        end
        sleep 2
        sinceid = incidents.last["incident"]["incidentid"].to_i
      end
      p "writing the closing bit"
      cache.write_text('{}]}')
    end

    def filter_data(incidents)
      p "#{incidents.count} before uniq"
      p "uniqifying"
      filtered_incidents= incidents.uniq
      p "#{incidents.count} after uniq"
      return filtered_incidents
    end
  end
end

# ===========
# = routine =
# ===========

if ARGV[0] == "cache"
  worker=PrintingPress::Worker.new
  cache=PrintingPress::Cache.new
  if cache.full?
    p "looks like your cache has data -- try deleting it first."
  else
    worker.fill_cache
  end  
elsif ARGV[0] == "print"
  book= PrintingPress::Book.new
  cache= PrintingPress::Cache.new
  book.print(incidents= cache.read)
else
  p "usage: ruby ushahidi2pdf.rb [cache|print]"
end
