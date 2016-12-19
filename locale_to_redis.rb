#! /usr/bin/env ruby
require 'optparse'
require 'yaml'
require 'redis'
require 'redis-namespace'

$redis = Redis.new

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