module DTK; module Common; class GritAdapter
  class FileAccess < self
    require File.expand_path('file_access/status', File.dirname(__FILE__))
    require File.expand_path('file_access/diff', File.dirname(__FILE__))
    include StatusMixin
    include DiffMixin
    def add_file(file_rel_path,content)
      content ||= String.new
      file_path = qualified_path(file_rel_path)
      chdir_and_checkout do
        File.open(file_path,"w"){|f|f << content}
        git_command(:add,file_path)
      end
    end

    def add_file_command(file_rel_path)
      chdir_and_checkout do
        file_path = qualified_path(file_rel_path)
        git_command(:add,file_path)
      end
    end

    def remove_file(file_rel_path)
      file_path = qualified_path(file_rel_path)
      chdir_and_checkout do
        git_command(:rm,file_path)
      end
    end

    def fetch(remote="origin")
      chdir_and_checkout do
        git_command(:fetch,remote)
      end
    end

    def commit(commit_msg,opts={})
      cmd_args = [:commit,"-a","-m",commit_msg]
      author = "#{opts[:author_username]||DefaultAuthor[:username]} <#{opts[:author_email]||DefaultAuthor[:email]}>"
      cmd_args += ["--author",author]
      chdir_and_checkout do
        #note using following because silent failure @grit_repo.commit_all(commit_msg)
        git_command(*cmd_args)
      end
    end
    DefaultAuthor = {
      :username => "dtk",
      :email => "dtk@reactor8.com"
    }

    #returns :equal, :local_behind, :local_ahead, or :branchpoint
    #type can be :remote_branch or :local_branch
    def ret_merge_relationship(type,ref,opts={})
      if (type == :remote_branch and opts[:fetch_if_needed])
        #TODO: this fetches all branches on the remote; see if anyway to just fetch a specfic branch
        #ref will be of form remote_name/branch
        fetch(ref.split("/").first)
      end
      other_grit_ref = 
        case type
         when :remote_branch
          @grit_repo.remotes.find{|r|r.name == ref}
         when :local_branch
          @grit_repo.heads.find{|r|r.name == ref}
         else
          raise Error.new("Illegal type parameter (#{type}) passed to ret_merge_relationship") 
        end
      unless other_grit_ref
        raise Error.new("Cannot find git ref (#{ref})")
      end
      
      other_sha = other_grit_ref.commit.id
      local_sha = @grit_repo.heads.find{|r|r.name == @branch}.commit.id
      
      if other_sha == local_sha then :equal
      else
        merge_sha = git_command__merge_base(@branch,ref)
        if merge_sha == local_sha then :local_behind
        elsif merge_sha == other_sha then :local_ahead
        else :branchpoint
        end
      end
    end

   private
     def qualified_path(file_rel_path)
       "#{@repo_dir}/#{file_rel_path}"
     end

    def git_command__merge_base(ref1,ref2)
      #chomp added below because raw griot command has a cr at end of line
      git_command(:merge_base,ref1,ref2).chomp
    end

     #TODO: otehr than to write file to directory may not need to chdir becauselooks liek grit uses --git-dir option
     def chdir_and_checkout(branch=nil,&block)
       branch ||= @branch
       Dir.chdir(@repo_dir) do 
         current_head = @grit_repo.head.name
         git_command(:checkout,branch) unless current_head == branch
         return unless block
         ret = yield
         unless current_head == branch
           git_command(:checkout,current_head)
         end
         ret
       end
     end
   end
end;end;end

