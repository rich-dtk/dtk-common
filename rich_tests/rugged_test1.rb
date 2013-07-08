#!/usr/bin/env ruby
#TODO: reqwrite using rspec
require 'rubygems'
lib_root = '../lib'
require File.expand_path("#{lib_root}/git_repo",File.dirname(__FILE__))
require 'pp'
repo_path = File.expand_path('fixtures/rugged_test1/repo1.git',File.dirname(__FILE__))
DtkCommon::GitRepo.new(repo_path).get_file_content('file_path')
