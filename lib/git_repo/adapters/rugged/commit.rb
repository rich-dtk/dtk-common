module DtkCommon
  class GitRepo::Adapter::Rugged
    class Commit < Obj
      def initialize(rugged_repo,rugged_commit)
        super(rugged_repo)
        @rugged_commit = rugged_commit
      end

      def tree()
        Tree.new(@rugged_repo,@rugged_commit.tree)
      end
    end
  end
end
