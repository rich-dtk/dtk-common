module DTK::Common; class GritAdapter
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

    def fetch_branch(remote="origin")
      chdir_and_checkout do
        git_command(:fetch,remote,@branch)
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

   private
     def qualified_path(file_rel_path)
       "#{@repo_dir}/#{file_rel_path}"
     end

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
end;end

