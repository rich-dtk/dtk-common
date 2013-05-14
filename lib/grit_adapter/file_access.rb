require 'colorize'

module DTK; module Common; class GritAdapter
  class FileAccess < self
    require File.expand_path('file_access/status', File.dirname(__FILE__))
    require File.expand_path('file_access/diff', File.dirname(__FILE__))
    include StatusMixin
    include DiffMixin
    def add_file(file_rel_path, content=nil)
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

    def pull(remote_branch,local_branch,remote=nil)
      remote ||= default_remote()
      chdir do
        git_command(:pull,remote,"#{remote_branch}:#{local_branch}")
      end
    end

    def reset_hard(remote_branch_ref)
      chdir do
        git_command(:reset,"--hard",remote_branch_ref)
      end
    end

    def fetch(remote=nil)
      remote ||= default_remote()
      chdir do
        git_command(:fetch,remote)
      end
    end

    def merge(remote_branch_ref)
      chdir_and_checkout do
        git_command(:merge,remote_branch_ref)
      end
    end

    def changed_files()
      # NOTE: There is issue with grit and git. Where grit.status will report file changed (modified)
      # and git status will not. Grit registers changing file time-stamp as change while git doesn't. This would 
      # not be a problem but `git push` will fail because of this. Following is fix for that.
      output = git_command(:status)
      grit_files = @grit_repo.status.files.select { |k,v| (v.type =~ /(A|M)/ || v.untracked) }
      changed_files = grit_files.select do |file|
        file_name = file.instance_of?(String) ? file : file.first
        output.include?(file_name)
      end

      # returns array of arrays (first element name of file)
      changed_files.to_a
    end

    def deleted_files()
      # returns array of arrays (first element name of file)
      @grit_repo.status.deleted().to_a 
    end

    def print_status()
      changes = [@grit_repo.status.changed(), @grit_repo.status.untracked(), @grit_repo.status.deleted()]
      puts "\nModified files:\n".colorize(:green) unless changes[0].empty?
      changes[0].each { |item| puts "\t#{item.first}" }
      puts "\nUntracked files:\n".colorize(:yellow) unless changes[1].empty?
      changes[1].each { |item| puts "\t#{item.first}" }
      puts "\nDeleted files:\n".colorize(:red) unless changes[2].empty?
      changes[2].each { |item| puts "\t#{item.first}" }
      puts ""
    end

    ##
    # Checks for changes add/delete/modified
    #
    def changed?
      !(changed_files() + deleted_files).empty?
    end

    ##
    # Method will add and remove all files, after commit with given msg
    #
    def add_remove_commit_all(commit_msg)
      chdir do
        # modified, untracked
        changed_files().each do |c_file|
          add_file_command(c_file.first)
        end
        # deleted
        deleted_files().each do |d_file|
          remove_file(d_file.first)
        end
        # commit 
        commit(commit_msg)
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

    # returns :equal, :local_behind, :local_ahead, or :branchpoint
    # type can be :remote_branch or :local_branch
    def ret_merge_relationship(type,ref,opts={})
      if (type == :remote_branch and opts[:fetch_if_needed])
        #TODO: this fetches all branches on the remote; see if anyway to just fetch a specfic branch
        #ref will be of form remote_name/branch
        #TODO: also see if more efficient to use git ls-remote
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

      local_sha = head_commit_sha()
      if opts[:ret_commit_shas]
        opts[:ret_commit_shas][:local_sha] = local_sha
      end

      unless other_grit_ref
        if type == :remote_branch
          return :no_remote_ref
        end
        raise Error.new("Cannot find git ref (#{ref})")
      end
      other_sha = other_grit_ref.commit.id
      if opts[:ret_commit_shas]
        opts[:ret_commit_shas][:other_sha] = other_sha
      end
      
      if other_sha == local_sha 
        :equal
      else
        #shas can be different but  they can have same content so do a git diff
        unless any_diffs?(local_sha,other_sha)
          return :equal
        end
        #TODO: see if missing or mis-categorizing any condition below
        if git_command__rev_list_contains?(local_sha,other_sha) then :local_ahead
        elsif git_command__rev_list_contains?(other_sha,local_sha) then :local_behind
        else :branchpoint
        end
      end
    end

    def head_commit_sha()
      head = @grit_repo.heads.find{|r|r.name == @branch}
      head && head.commit.id
    end
    def find_remote_sha(ref)
      remote = @grit_repo.remotes.find{|r|r.name == ref}
      remote && remote.commit.id
    end

    def add_branch?(branch)
      unless branches().include?(branch)
        add_branch(branch)
      end
    end
    def add_branch(branch)
      chdir_and_checkout() do 
        git_command(:branch,branch)
      end
    end
    def remove_branch?(branch)
      if branches().include?(branch)
        remove_branch(branch)
      end
    end
    def remove_branch(branch)
      checkout_branch = @branch
      chdir_and_checkout(checkout_branch,:stay_on_checkout_branch => true) do
        git_command(:branch,"-d",branch)
      end.first
    end

   private

    # 
    # There is issue with Grit 1.8.7 and 1.9.3 version have diffrent returns on changed/deleted files
    #
    # 1.8.7 => Returns array of arrays where file name is first elemenet
    # 1.9.3 => Returns hash where keys are file names
    #
    # No need for it now, but when refactoring code use this instead of .to_a fix
    def grit_compability_transform(grit_files)
      grit_files.instance_of?(Hash) ? grit_files.keys : grit_files.collect { |element| element.first }
    end

    def default_remote()
      "origin"
    end

    def qualified_path(file_rel_path)
      "#{@repo_dir}/#{file_rel_path}"
    end

    def git_command__rev_list_contains?(container_sha,index_sha)
      rev_list = git_command(:rev_list,container_sha)
      !rev_list.split("\n").grep(index_sha).empty?()
    end

    #TODO: would like more efficient way of doing this as opposed to below which first produces object with full diff as opposed to summary
    def any_diffs?(ref1,ref2)
      not @grit_repo.diff(ref1,ref2).empty?
    end

    #TODO: may  determine where --git-dir option makes an actual chdir unnecssary
    def chdir_and_checkout(branch=nil,opts={},&block)
      branch ||= @branch
      chdir do 
        current_head = @grit_repo.head.name
        git_command(:checkout,branch) unless current_head == branch
        return unless block
        ret = yield
        unless opts[:stay_on_checkout_branch] or (current_head == branch)
           git_command(:checkout,current_head)
        end
        ret
      end
    end

    def chdir(&block)
      Dir.chdir(@repo_dir){yield}
    end



  end
end;end;end

