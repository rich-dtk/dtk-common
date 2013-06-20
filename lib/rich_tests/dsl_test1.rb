#!/usr/bin/env ruby
require 'rubygems'
lib_root = '../'
require File.expand_path("#{lib_root}/dsl",File.dirname(__FILE__))
require 'pp'
DtkCommon::DSL::FileParser.parse_content(:component_module_refs,'')
