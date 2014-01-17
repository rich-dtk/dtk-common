require File.expand_path('lib/gitolite/init.rb', File.dirname(__FILE__))


manager = Gitolite::Manager.new('/home/git/gitolite-admin')

# DEBUG SNIPPET >>>> REMOVE <<<<
require 'pp'
pp "Start >>>"

pp manager.open_repo('r8--cm--bootstrap')


pp "DOne!"