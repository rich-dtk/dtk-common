module DtkCommon
  class GitRepo::Adapter::Rugged
    module CommonMixin
      private
      def initialize(rugged_repo)
        @rugged_repo = rugged_repo
      end
      def lookup(sha)
        @rugged_repo.lookup(sha)
      end
    end

    class Obj
      include CommonMixin
    end
  end
end
