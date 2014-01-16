# use to require all needed files needed for running dtk-common gitolite lib
require 'grit'; require 'erubis'

require File.expand_path('manager.rb', File.dirname(__FILE__))
require File.expand_path('configuration.rb', File.dirname(__FILE__))
require File.expand_path('errors.rb', File.dirname(__FILE__))

require File.expand_path('grit/adapter.rb', File.dirname(__FILE__))
require File.expand_path('grit/file_access.rb', File.dirname(__FILE__))

require File.expand_path('utils.rb', File.dirname(__FILE__))
require File.expand_path('repo.rb', File.dirname(__FILE__))
require File.expand_path('user_group.rb', File.dirname(__FILE__))