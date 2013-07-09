module DtkCommon
  class GitRepo::Adapter::Rugged
    class Branch
      attr_reader :rugged_repo,:branch
      def initialize(rugged_repo,branch)
        @rugged_repo = rugged_repo
        @branch = branch
      end
    end

    module CommonMixin
     private
      def branch()
        @repo_branch.branch()
      end
      def rugged_repo()
        @repo_branch.rugged_repo()
      end

      def lookup(sha)
        rugged_repo().lookup(sha)
      end
    end

    class Obj
      include CommonMixin

      def initialize(repo_branch)
        @repo_branch = repo_branch
      end
    end
  end
end

