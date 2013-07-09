module DtkCommon
  class GitRepo::Adapter::Rugged
    class Commit
      def initialize(rugged_commit)
        @rugged_commit = rugged_commit
      end

      def tree()
        Tree.new(@rugged_commit.tree)
      end
    end
  end
end
