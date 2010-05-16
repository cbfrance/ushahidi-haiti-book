require 'rubygems'
$LOAD_PATH.unshift("/Users/chris/git/prawn/lib")
require 'prawn'

Prawn.debug = true

builder = Prawn::DocumentBuilder.new
font = "Times"

unless ARGV.length == 1
  puts "Usage: ruby csv2pdf.rb your_ushahidi_export_file.csv > output.pdf\n"
  exit
end

input_file = ARGV[0]

f = File.open(input_file, "r")
f.each_line { |line|
  words = line.split('%t')
  builder.text(words[0].tr_s('"', '').strip)
  builder.start_new_page
}


document = builder.compile
document.render_file("book.pdf")
