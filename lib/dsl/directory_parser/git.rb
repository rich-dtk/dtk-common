module DtkCommon; module DSL
  class DirectoryParser
    class Git < self
      def initialize(repo_path,directory_type,branch='master')
        super(directory_type)
        @repo_path = repo_path
        @branch = branch
      end
     private
      def all_files_from_root()
        raise Error.new("not written yet")
      end
      def get_content(file_path)
        #TODO: use method from common grit adapter (may have to write if not there already that reads git object db to get
        #content on branch
        raise Error.new("not written yet")
      end
    end
  end
end; end
