#!/usr/bin/env ruby
require 'rubygems'
lib_root = '../lib'
require File.expand_path("#{lib_root}/dsl",File.dirname(__FILE__))
require 'pp'
Dir['fixtures/dsl_test1/*/*'].each do |component_module_refs_rel_path|
  cmr_path = File.expand_path(component_module_refs_rel_path,File.dirname(__FILE__))
  path_info = component_module_refs_rel_path.split("/")
  service_mod = path_info[2]
  puts "processing service module #{service_mod.gsub(/^sm-/,'')}:\n"
  file_content = File.open(cmr_path).read()
  pp DtkCommon::DSL::FileParser.parse_content(:component_module_refs,file_content)
  puts "\n"
end
