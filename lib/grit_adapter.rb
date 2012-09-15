#TODO: should I move all methods that user grit.git to file_access?
require 'grit'
require 'fileutils'
require 'thread'

module DTK
  module Common
    require File.expand_path('require_first',File.dirname(__FILE__))
    class GritAdapter 
      require File.expand_path('grit_adapter/file_access', File.dirname(__FILE__))
      require File.expand_path('grit_adapter/object_access', File.dirname(__FILE__))
      def initialize(repo_dir,branch=nil,opts={})
        @repo_dir = repo_dir
        @branch = branch
        @grit_repo = nil
        begin
          @grit_repo = (opts[:init] ?  ::Grit::Repo.init(repo_dir) : ::Grit::Repo.new(repo_dir))
          @branch ||= default_branch()
        rescue ::Grit::NoSuchPathError
          repo_name = repo_dir.split("/").last.gsub("\.git","")
          #TODO: change to usage error
          raise Error.new("repo (#{repo_name}) does not exist")
        rescue => e
          raise e
        end
      end

      attr_reader :branch,:repo_dir

      def self.clone(target_repo_dir,git_server_url,opts={})
        if File.directory?(target_repo_dir)
          if opts[:delete_if_exists]
            FileUtils.rm_rf target_repo_dir
          else
            raise Error.new("trying to create a repo directory (#{target_repo_dir}) that exists already")
          end
        end
        clone_cmd_opts = {:raise => true, :timeout => 60}
        clone_args = [git_server_url,target_repo_dir]
        if branch = opts[:branch] 
          clone_args += ["-b",branch]
        end
        ::Grit::Git.new("").clone(clone_cmd_opts,*clone_args)
        ret = new(*[target_repo_dir,opts[:branch]].compact)
        #make sure remote branch exists; ::Grit::Git.new("").clone silently uses master if remote branch does not exist
        if branch = opts[:branch]
          branches = ret.branches()
          unless branches.include?(opts[:branch])
            FileUtils.rm_rf target_repo_dir
            raise Error.new("Remote branch (#{opts[:branch]}) does not exist")
          end
        end
        ret
      end

      def branches()
        @grit_repo.branches.map{|h|h.name}
      end

      def ls_r(depth=nil,opts={})
        tree_contents = tree.contents
        ls_r_aux(depth,tree_contents,opts)
      end

      def path_exists?(path)
        not (tree/path).nil?
      end

      def file_content(path)
        tree_or_blob = tree/path
        tree_or_blob && tree_or_blob.kind_of?(::Grit::Blob) && tree_or_blob.data
      end

      def push()
        Git_command__push_mutex.synchronize do 
          git_command(:push,"origin", "#{@branch}:refs/heads/#{@branch}")
        end
      end
      Git_command__push_mutex = Mutex.new

      def pull()
        git_command(:pull,"origin",@branch)
      end

     private
      def default_branch()
        branches = branches()
        if branches.include?('master')
          return 'master'
        elsif branches.size == 1
          branches.first
        else
          raise Error.new("Cannot find a unique default branch")
        end
      end

      def tree()
        @grit_repo.tree(@branch)
      end

      def ls_r_aux(depth,tree_contents,opts={})
        ret = Array.new
        return ret if tree_contents.empty?
        if depth == 1
          ret = tree_contents.map do |tc|
            if opts[:file_only]
              tc.kind_of?(::Grit::Blob) && tc.name 
            elsif opts[:directory_only]
              tc.kind_of?(::Grit::Tree) && tc.name
            else
              tc.name
            end
          end.compact
          return ret
        end

        tree_contents.each do |tc|
          if tc.kind_of?(::Grit::Blob)
            unless opts[:directory_only]
              ret << tc.name
            end
          else
            dir_name = tc.name
            ret += ls_r_aux(depth && depth-1,tc.contents).map{|r|"#{dir_name}/#{r}"}
          end
        end
        ret
      end

      def git_command(cmd,*args)
        @grit_repo.git.send(cmd, cmd_opts(),*args)
      end
      def cmd_opts()
        {:raise => true, :timeout => 60}
      end
    end
  end
end
