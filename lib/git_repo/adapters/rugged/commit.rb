module DtkCommon
  class GitRepo::Adapter::Rugged
    class Commit
      def initialize(rugged_commit)
        @rugged_commit = rugged_commit
      end
    end
  end
end
