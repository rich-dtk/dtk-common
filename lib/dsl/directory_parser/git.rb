module DtkCommon; module DSL
  class DirectoryParser
    class Git < self
      def initialize(repo_path,directory_type,branch='master')
        super(directory_type)
        puts repo_path
        @repo_path = repo_path
        @branch = branch
      end
     private
      def all_files_from_root()
        # TODO: Watch version here
        output = `git --git-dir=#{@repo_path} ls-tree --full-tree -r HEAD`
        puts output
      end
      def get_content(file_path)
        output = `git --git-dir=#{@repo_path} show  HEAD:#{file_path}`
        output = '{}' if output.empty?
        output
      end
    end
  end
end; end
