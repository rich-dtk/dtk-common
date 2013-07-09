module DtkCommon
  class GitRepo::Adapter::Rugged
    class Blob < Obj
      def initialize(repo_branch,rugged_blob)
        super(repo_branch)
        @rugged_blob = rugged_blob
      end
      
      def content()
        lookup(@rugged_blob[:oid]).read_raw.data
      end
    end
  end
end
