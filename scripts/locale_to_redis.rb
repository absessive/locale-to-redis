#! /usr/bin/env ruby
require 'optparse'
require 'yaml'
require 'redis'
require 'redis-namespace'
require 'colorize'
# require 'google-api-client'


# Define all the helper methods here
def create_redis_connection(namespace)
	$redis = Redis::Namespace.new(namespace, redis: Redis.new)
end

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

def save_locale_to_redis(options)
	filename = options[:filename]
	# Load YAML file
	hash = YAML.load_file(filename)
	# Find the language for locale
	lang = hash.keys.first
	hash = hash[hash.keys.first]
	
	puts "########################################################################".red
	puts "##############            Adding Keys to Redis         #################".green
	puts "########################################################################".red
	recurse(hash) do |path, value|
		redis_key = "#{lang}.#{path}"
		# If the options to delete existing key is set, and the key-value pair exists
		if (options[:delete])
			$redis.set("#{lang}.#{path}",value)
		else
			puts "Skipping #{redis_key}"
		end
    end
end

# Parsing options begin here
options = {}
required_options = [:namespace, :filename]
begin
	opt_parser = OptionParser.new do |opts|
		opts.on('-n', '--namespace NAMESPACE', "Namespace (required)") { |n| options[:namespace] = n}
		opts.on('-f', '--filename FILENAME', "File name (required)") { |f| options[:filename] = f }
		opts.on('-d', '--delete', "Delete existing keys for that namespace") { |d| options[:delete] = d }
	end.parse!

	required_options.each do |k|
		raise OptionParser::MissingArgument.new(k) if options[k].nil?		
	end
	# Create Redis Connection
	create_redis_connection(options[:namespace])
	save_locale_to_redis(options)
rescue OptionParser::MissingArgument => e
	puts "Argument missing #{e}"
	exit(1)
end
