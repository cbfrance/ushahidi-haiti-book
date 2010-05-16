require 'rubygems'
require "/Users/chris/git/prawn/examples/example_helper.rb"

builder = Prawn::DocumentBuilder.new

# tutorial on using ruby structs to read CSV http://www.devdaily.com/blog/post/ruby/example-split-csv-rows-data-into-fields-commas-ruby

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
