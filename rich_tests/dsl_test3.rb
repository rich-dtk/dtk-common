#!/usr/bin/env ruby
require 'rubygems'
lib_root = '../lib'
require File.expand_path("#{lib_root}/dsl",File.dirname(__FILE__))
require 'pp'

service_repo_loc = '/home/git/repositories'

if Dir[service_repo_loc]
  service_directories = Dir.entries(service_repo_loc).select {|entry| entry.to_s.include?('--sm--') }
  service_directories.each do |service_repo|
    dir_parser = DtkCommon::DSL::DirectoryParser::Git.new(:service_module, "#{service_repo_loc}/#{service_repo}")
    pp dir_parser.parse_directory(:component_module_refs)
  end
else
  puts "Not able to find '#{service_repo_loc}' ment to be run on repo-manager"
end
