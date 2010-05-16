
#!/usr/bin/ruby

# require 'rubygems'
# require 'prawn'
# pdf = Prawn::Document.new

# based on http://www.devdaily.com/blog/post/ruby/example-split-csv-rows-data-into-fields-commas-ruby

# ==================================================================================
# = starting with a CSV export from ushahidi,
# = you will need to edit the header row to be title, date, description, location'
# = and delete the other fields
# ==================================================================================

# define a "Report" class to represent the three expected columns
class REPORT <
  Struct.new(:title, :date, :location, :description)
  def print_csv_record
    title.length==0 ? printf(",") : printf("\"%s\",", title)
    date.length==0 ? printf(",") : printf("\"%s\",", date)
    location.length==0 ? printf("") : printf("\"%s\"", location)
    description.length==0 ? printf("") : printf("\"%s\"", description)
    printf("\n")
    # TODO not spitting out the pdf yet.
    # pdf.text("Prawn Rocks")
    # pdf.render_file('prawn.pdf')
  end
end

unless ARGV.length == 1
  puts "Not the right number of arguments."
  puts "Usage: ruby csv2pdf.rb your_ushahidi_export_file.csv > output.pdf\n"
  exit
end

# get the input filename from the command line
input_file = ARGV[0]

# define an array to hold the Person records
arr = Array.new

# loop through each record in the csv file, adding
# each record to our array.
f = File.open(input_file, "r")
f.each_line { |line|
  words = line.split(',')
  r = REPORT.new
  # do a little work here to get rid of double-quotes and blanks
  r.title = words[0].tr_s('"', '').strip
  r.date = words[1].tr_s('"', '').strip
  r.location = words[2].tr_s('"', '').strip
  r.description = words[3].tr_s('"', '').strip
  arr.push(r)
}

# print out all the sorted records (just print to stdout)
arr.each { |p|
  p.print_csv_record
}
