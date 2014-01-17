module Gitolite
  class UserGroup

    include Utils

    GROUP_CONFIG_PATH = 'conf/group-defs'
    # we need this to make sure that group is there but dummy name is needed to pass gitolite check
    # DUMMY_USERNAME = 'r8_dummy_group_user'

    UserGroupTemplate = Erubis::Eruby.new <<-eos
      @<%=user_group.name%> = <%= user_group.members.empty? ? 'r8_dummy_group_user' : user_group.members.join(' ') %>
    eos

    attr_accessor :name, :members, :logger

    def initialize(group_name, logger_, gitolite_path, gitolite_branch = "master")
      @name    = group_name
      @members = []
      @commit_messages = []
      @group_file_path = File.join(GROUP_CONFIG_PATH, "#{@name}.conf")
      @gitolite_admin_repo ||= Git::FileAccess.new(gitolite_path, gitolite_branch)
      @logger = logger_

      if exists?
        load_group()
      end
    end

    def load_group()
      raw_content = @gitolite_admin_repo.file_content(@group_file_path)

      unless raw_content
        raise Gitolite::NotFound, "Configuration file for user group (#{@name}) does not exist"
      end

      raw_content.each_line do |l|
        l.chomp!()
        if l =~ /.*=(.+)$/
          raw_members = $1
          @members = raw_members.chomp().split(' ')
        else
          raise ::Error::GitoliteParsing, "Parsing groups error: (#{l})"
        end
      end
    end

    def exists?
      !@gitolite_admin_repo.file_content(@group_file_path).nil?
    end

    def any_changes?
      !@commit_messages.empty?
    end

    def add_git_usernames(array_of_usernames)
      unless is_subset?(@members, array_of_usernames)
        @members.concat(array_of_usernames)
        @members.uniq!
        @commit_messages << "Added users (#{array_of_usernames.join(', ')}) to group '#{@name}'"
      end
    end

    def set_git_usernames(array_of_usernames)
      # we clean current member since we are setting all gitusernames (not adding)
      @members = []
      add_git_usernames(array_of_usernames)
    end

    def remove_git_usernames(array_of_usernames)
      if is_subset?(@members, array_of_usernames)
        @members = @members - array_of_usernames
        @commit_messages << "Removed users (#{array_of_usernames.join(', ')}) from group '#{@name}'"  
      end
    end

    def commit_changes(override_commit_message = nil)
      # we check if there were changes
      unless @commit_messages.empty?
        content = file_content()

        commit_msg = override_commit_message || @commit_messages.join(', ')

        @gitolite_admin_repo.add_file(@group_file_path,content)
        @gitolite_admin_repo.commit(commit_msg)
        
        @logger.info(commit_msg)
      else
        @logger.info("There has been no changes on group '#{@name}' skipping gitolite commit.")
      end
    end


    def file_content()
      UserGroupTemplate.result(:user_group => self)
    end

  end
end