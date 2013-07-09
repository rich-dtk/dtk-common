module DtkCommon
  gem 'rugged', GitRepo::NailedRuggedVersion
  require 'rugged'
  class GitRepo; class Adapter
    class Rugged < self                    
      require File.expand_path('rugged/commit',File.dirname(__FILE__))
      require File.expand_path('rugged/tree',File.dirname(__FILE__))

      def initialize(repo_path)
        @repo = ::Rugged::Repository.new(repo_path)
      end
      def get_file_content(path,branch='master')
        unless commit = get_commit(branch)
          raise ErrorUsage.new("Branch (#{branch} not found in repo (#{pp_repo()})")
        end
        commit.tree.get_file_content(path)
      end

     private
       def get_commit(branch)
         if rugged_ref = @repo.refs.find {|ref|ref.name == "refs/heads/#{branch}"}
           Commit.new(@repo.lookup(rugged_ref.target))
         end
       end 

       def pp_repo()
         @repo.path()
       end
    end
  end; end
end
