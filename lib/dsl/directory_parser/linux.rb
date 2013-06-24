module DtkCommon; module DSL
  class DirectoryParser
    class Linux < self
      def initialize(directory_type,directory_root)
        super(directory_type)
        @directory_root = directory_root
      end
     private
      def all_files_from_root()
        Dir.chdir(@directory_root) do
          Dir["*/**"]
        end
      end

      def get_content(rel_file_path)
        file_path = "#{@directory_root}/#{rel_file_path}"
        File.open(file_path).read()
      end
    end
  end
end; end
