require File.expand_path('../../git_repo.rb',File.dirname(__FILE__))
module DtkCommon; module DSL
  class DirectoryParser
    class Git < self
#      def initialize(repo_path,directory_type,branch='master')
      def initialize(directory_type,repo_path,branch='master')
        super(directory_type)
 #       puts repo_path
        @repo_path = repo_path
        @repo_branch = GitRepo::Branch.new(repo_path,branch)
      end

      def self.implements_method?(method_name)
        if DirectoryParserMethods.include?(method_name)
          case method_name
           when :parse_directory
            GitRepo::Branch.implements_method?(:get_file_content)
           else
            true
          end
        end
      end

     private
      def all_files_from_root()
        # TODO: Watch version here
#        output = `git --git-dir=#{@repo_path} ls-tree --full-tree -r HEAD`
        @repo_branch.list_files()
      end
      def get_content(file_path)
#        output = `git --git-dir=#{@repo_path} show  HEAD:#{file_path}`
#        output = '{}' if output.empty?
#        output
        #If file does not exsist will return nil
        @repo_branch.get_file_content(file_path)
      end
    end
  end
end; end
