module DtkCommon
  class GitRepo::Adapter::Rugged
    class Blob
      def initialize(rugged_blob)
        @rugged_blob = rugged_blob
      end
      
      def content()
        @rugged_blob.read_raw.data
      end
    end
  end
end
