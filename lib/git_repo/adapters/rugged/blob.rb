module DtkCommon
  class GitRepo::Adapter::Rugged
    class Blob < Obj
      def initialize(rugged_repo,rugged_blob)
        super(rugged_repo)
        @rugged_blob = rugged_blob
      end
      
      def content()
        lookup(@rugged_blob[:oid]).read_raw.data
      end
    end
  end
end
