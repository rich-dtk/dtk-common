  # This class is used to read gitolite repo config file. File is loaded and paramters are accessible via
  # class members. After needed manipulation class will be saved as gitolite conf file.

module Gitolite
  class Repo

    include Utils

    attr_accessor :repo_name, :rights_hash, :commit_messages, :user_groups, :logger
    attr_reader   :repo_dir_path

    GIOLITE_ALL_GROUP = '@all'

    #
    # We check if there are users in addition to tenant with line,
    # (repo_conf.rights_hash.values.flatten.size > 1)
    # In case no, we do not give permission to tenant even
    #

    RepoConfTemplate = ::Erubis::Eruby.new <<-eos
    include "groups-defs/*.conf"
    repo    <%= repo_conf.repo_name %>
      <% if repo_conf.rights_hash.values.flatten.size > 1 %>
        <% repo_conf.rights_hash.each do |k, v| %>
          <% unless v.empty? %>
            <%=k%> = <%=v.join(' ') %>
          <% end %>
        <% end %>
      <% end %>
    eos

    class << self

      def get_repo_type(repo_name)
        repo_name.match(/\-\-cm\-\-/) ? 'component' : 'service'
      end

    end

    def initialize(repo_name, configuration_, logger_, gitolite_path, gitolite_branch="master")
      # IMPORTANT! Tenants user are always included with each module

      @rights_hash = { 'R' => [], 'W' => [], 'RW' => ['@tenants'], 'RW+' => []}
      @repo_name = repo_name
      @user_groups = []
      @commit_messages = []
      @repo_conf_file_path = configuration_.repo_path(repo_name)
      @repo_dir_path       = configuration_.bare_repo_path(repo_name)
      @gitolite_admin_repo ||= Git::FileAccess.new(gitolite_path, gitolite_branch)
      @logger = logger_

      if exists?
        load_repo()
      end
    end

    def rights_for_username(username)
      @rights_hash.each do |k,v|
        if v.include?(username)
          return k
        end
      end

      return nil
    end

    def remove_username(username)
      @rights_hash.each do |k,v|
        if v.include?(username)
          v.delete(username)
          @commit_messages << "Removed access rights ('#{k}') for user/group '#{username}'"
        end
      end
    end

    def remove_group(group_name)
      remove_username("@#{group_name}")
    end

    def add_username_with_rights(username, access_rights)
      # if we get nil that means that we have to delete user from its permission stack
      if access_rights.nil?
        return remove_username(username)
      end

      # Only make changes if this is new user/group
      unless @rights_hash[access_rights.upcase].include?(username)
        remove_username(username)

        @rights_hash[access_rights.upcase] << username
        @commit_messages << "Added access rights ('#{access_rights}') for user/group '#{username}', in repo '#{@repo_name}'"

        # add to user groups if user group is added
        if username.match(/^@/)
          @user_groups << username
        end
      end
    end

    def add_user_group_with_rights(group_name, access_rights)
      add_username_with_rights("@#{group_name}", access_rights)
    end

    def add_all_with_rights(access_rights)
      add_username_with_rights(GIOLITE_ALL_GROUP, access_rights)
    end

    def branches
      Git::FileAccess.new(@repo_dir_path).branches()
    end

    def exists?
      !@gitolite_admin_repo.file_content(@repo_conf_file_path).nil?
    end

    def any_changes?
      !@commit_messages.empty?
    end

    def commit_changes(override_commit_message = nil)
      unless @commit_messages.empty?
        content = configuration_content()
        validate_gitolite_conf_file(content)

        commit_msg = override_commit_message || @commit_messages.join(', ')

        @gitolite_admin_repo.add_file(@repo_conf_file_path,content)
        @gitolite_admin_repo.commit(commit_msg)

        @logger.info(commit_msg)
      else
        @logger.info("There has been no changes on repo '#{@repo_name}' skipping gitolite commit.")
      end
    end

    def file_content(path)
      Git::FileAccess.new(@repo_dir_path).file_content(path)
    end

    def file_content_and_size(path)
      Git::FileAccess.new(@repo_dir_path).file_content_and_size(path)
    end

    def file_list(depth=nil)
      Git::FileAccess.new(@repo_dir_path).ls_r(depth)
    end

  private

    def configuration_content()
      RepoConfTemplate.result(:repo_conf => self)
    end

    def load_repo()
      raw_content = @gitolite_admin_repo.file_content(@repo_conf_file_path)

      unless raw_content
        raise ::Error::NotFound, "Configuration file for repo (#{repo_name}) does not exist"
      end

      raw_content.each_line do |l|
        l.chomp!()
        if l =~ /^[ ]*repo[ ]+([^ ]+)/
          unless $1 == repo_name
            raise Error::GitoliteParsing, "Parsing error: expected repo to be (${repo_name} in (#{l})"
          end
        elsif l =~ /[ ]*([^ ]+)[ ]*=[ ]*(.+)$/
          access_rights = $1
          users = $2
          users.scan(/[^ ]+/) do |user|
            unless access_rights.match(/R|W|RW|RW+/)
              raise  Error::GitoliteParsing, "Unexpected access rights while parsing file '#{access_rights}'"
            end

            @rights_hash[access_rights.to_s] << user unless @rights_hash[access_rights.to_s].include?(user)

            # add to user groups if present
            if user.match(/^@/)
              @user_groups << user
            end
          end
        elsif l.strip.empty? || l.strip().match(/^include/)
          #no op
        else
          raise ::Error::GitoliteParsing, "Parsing repo error: (#{l})"
        end
      end
    end


  end

end
