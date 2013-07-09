module DtkCommon
  class GitRepo::Adapter::Rugged
    class Tree
      def initialize(rugged_tree)
        @rugged_tree = rugged_tree
      end

      def get_file_content(path)
        if blob = get_blob(path)
          blob.content
        end
      end

     private
      def get_blob(path)
        ret = nil
        dir = ""; file_part = path
        if path =~ /(.+\/)([^\/]+$)/
          dir = $1; file_part = $2
        end
        @rugged_tree.walk_blobs do |root,entry|
          if root == dir and entry.name == file_part
            return Blob.new(entry)
          end
        end
        ret
      end

    end
  end
end
