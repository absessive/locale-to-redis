#! /usr/bin/env ruby
require 'optparse'
require 'yaml'
require 'csv'

filename = if ARGV.length == 1
  ARGV[0]
elsif ARGV.length == 0
  "/path/to/project/config/locales/new.yml"
else
  ARGV[0]
end

unless filename
  puts "Usage: locale_script.rb filename '{export}' '{key_to_export}'"
  exit(1)
end

hash = YAML.load_file(filename)
hash = hash[hash.keys.first]

def recurse(obj, current_path = [], &block)
  if obj.is_a?(String)
    path = current_path.join('.')
    yield [path, obj]
  elsif obj.is_a?(Hash)
    obj.each do |k, v|
      recurse(v, current_path + [k], &block)
    end
  end
end

unless ARGV[1]
  recurse(hash) do |path, value|
    puts path
  end
end

if ARGV[1] == 'export' && ARGV[2].nil?
  puts "EXPORTING keys to file"
  target = File.open('exported_locales.csv', 'w')
  target.write("Key,Value\n")
  recurse(hash) do |path, value|
    key = ARGV[2] ? ARGV[2] : ''
    target.write("#{path.upcase},#{value}\n") if path.include? key
  end
end  

if ARGV[3] == 'csv'
  puts "EXPORTING as CSV"
  target = CSV.open('rate_analysis_keys.csv', 'w') do |csv|
    csv << ["Key", "Value"]
    recurse(hash) do |path, value|
      key = ARGV[2] ? ARGV[2] : ''
      csv << [path.upcase, value] if path.include? key    
    end
  end
elsif ARGV[3] == 'properties'
  puts "Exporting as '.properties'"
  file_name = ARGV[2].nil? ? 'export_locales.properties' : "#{ARGV[2]}.properties"
  target = File.open(file_name, 'w')
  recurse(hash) do |path, value|
    key = ARGV[2] ? ARGV[2] : ''
    if path.include? key
      target.write("#{path.upcase}=#{value}\n")
      target.write("#{path.upcase.gsub('._TEXT', '._KEYTEXT')}=\n")
    end
  end
end