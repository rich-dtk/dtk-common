#!/usr/bin/env ruby
#TODO: reqwrite using rspec
require 'rubygems'
lib_root = '../lib'
require File.expand_path("#{lib_root}/git_repo",File.dirname(__FILE__))
require 'pp'
repo_path = File.expand_path('fixtures/rugged_test1/repo1.git',File.dirname(__FILE__))
repo = DtkCommon::GitRepo.new(repo_path)
%w{test_file.txt dir/nested.txt dir/nested_dir/second_level.txt bad n/bad}.each do |path|
  begin
    content = repo.get_file_content(path,'branch1')
    pp [path,content]
   rescue => e
    pp [path,e.class,e.to_s]
  end
end
