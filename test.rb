require 'grit'
require 'erubis'

require File.expand_path('lib/gitolite/manager.rb', File.dirname(__FILE__))
require File.expand_path('lib/gitolite/configuration.rb', File.dirname(__FILE__))
require File.expand_path('lib/gitolite/errors.rb', File.dirname(__FILE__))

require File.expand_path('lib/gitolite/grit/adapter.rb', File.dirname(__FILE__))
require File.expand_path('lib/gitolite/grit/file_access.rb', File.dirname(__FILE__))

require File.expand_path('lib/gitolite/utils.rb', File.dirname(__FILE__))
require File.expand_path('lib/gitolite/repo.rb', File.dirname(__FILE__))
require File.expand_path('lib/gitolite/user_group.rb', File.dirname(__FILE__))



manager = Gitolite::Manager.new('/home/git/gitolite-admin')

# DEBUG SNIPPET >>>> REMOVE <<<<
require 'pp'
pp "Start >>>"

pp manager.open_repo('r8--cm--bootstrap')


pp "DOne!"