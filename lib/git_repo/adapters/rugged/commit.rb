module DtkCommon
  class GitRepo::Adapter::Rugged
    class Commit < Obj
      def initialize(repo_branch,rugged_commit)
        super(repo_branch)
        @rugged_commit = rugged_commit
      end

      def tree()
        Tree.new(@repo_branch,@rugged_commit.tree)
      end
    end
  end
end
