#!/usr/bin/env ruby
require 'rubygems'
lib_root = '../lib'
require File.expand_path("#{lib_root}/dsl",File.dirname(__FILE__))
require 'pp'
Dir['fixtures/dsl_test2/*'].each do |service_mod_rel_path|
  service_mod_path = File.expand_path(service_mod_rel_path,File.dirname(__FILE__))
  dir_parser = DtkCommon::DSL::DirectoryParser::Linux.new(:service_module,service_mod_path)
  pp dir_parser.parse_directory(:component_module_refs)
end
