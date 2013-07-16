require File.expand_path('../../git_repo.rb',File.dirname(__FILE__))

module DtkCommon
  gem 'rugged', GitRepo::NailedRuggedVersion
  require 'rugged'
  class GitRepo; class Adapter
    class Rugged < self                    
      require File.expand_path('rugged/common',File.dirname(__FILE__))
      require File.expand_path('rugged/commit',File.dirname(__FILE__))
      require File.expand_path('rugged/tree',File.dirname(__FILE__))
      require File.expand_path('rugged/blob',File.dirname(__FILE__))
      include CommonMixin

      def initialize(repo_path,branch=nil)
        if branch.nil?
          raise Error.new("Not implemented yet creating Rugged adapter w/o a branch")
        end
        @repo_branch = Branch.new(::Rugged::Repository.new(repo_path),branch)
      end

      def get_file_content(path)
        get_tree().get_file_content(path)
      end

      def list_files()
         get_tree().list_files()
      end
      
     private
      def get_tree()
        get_commit().tree()
      end

      def get_commit()
        if rugged_ref = rugged_repo().refs.find {|ref|ref.name == "refs/heads/#{branch}"}
          Commit.new(@repo_branch,lookup(rugged_ref.target))
        else
          raise ErrorUsage.new("Branch (#{branch} not found in repo (#{pp_repo()})")
        end
      end 
      
      def pp_repo()
        rugged_repo().path()
      end
    end
  end; end
end
