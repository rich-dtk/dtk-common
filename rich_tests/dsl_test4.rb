#!/usr/bin/env ruby
require 'rubygems'
lib_root = '../lib'
require File.expand_path("#{lib_root}/dsl",File.dirname(__FILE__))
require 'pp'
class DtkCommon::DSL::DirectoryParser::Git
  public :all_files_from_root
end

Dir.chdir(File.dirname(__FILE__)) do 
  Dir['fixtures/dsl_test4/*'].each do |service_mod_rel_path|
    service_mod_path = File.expand_path(service_mod_rel_path,File.dirname(__FILE__))
    dir_parser = DtkCommon::DSL::DirectoryParser::Git.new(:service_module,service_mod_path)

    puts "-------------------------------------------------"
    puts "File: #{service_mod_rel_path.split('/').last}"
    puts "File list"
    
    pp dir_parser.all_files_from_root()
    puts "----\n"
    puts "Parse service_module"
    dir_parser.parse_directory(:component_module_refs)
  end
end

