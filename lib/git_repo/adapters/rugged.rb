module DtkCommon
  gem 'rugged', GitRepo::NailedRuggedVersion
  require 'rugged'
  class GitRepo ; class Adapter
    class Rugged < self                    
      def initialize(repo_path)
        @repo = ::Rugged::Repository.new(repo_path)
      end
      def get_file_content(path,branch='master')
        pp :foo
      end
    end
  end; end
end
