require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'

Prawn.debug = true

  pdf = Prawn::Document.new(:page_layout => :landscape)
  
  unless ARGV.length == 1
    puts "Usage: ruby csv2pdf.rb your_ushahidi_export_file.csv > output.pdf\n"
    exit
  end
  
  pdf.font_families.update("Hoefler" => { :normal => "Hoefler Text.dfont" })
  pdf.font("Hoefler", :style => :normal)
  pdf.font_size 15
  
  input_file = ARGV[0]
  
  x_pos = ((pdf.bounds.width / 2) - 150) 
  y_pos = ((pdf.bounds.height / 2) + 100) 

  pdf.bounding_box([x_pos, y_pos], :width => 300, :height => 400) do  
    f = File.open(input_file, "r")
    f.each_line { |line|
      words = line.split('%t')
      pdf.text(words[0].tr_s('"', '').strip.capitalize)
      pdf.start_new_page
    }
  end

pdf.render_file("book.pdf")

