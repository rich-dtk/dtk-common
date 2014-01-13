module Gitolite
  class Manager

    attr_accessor :repos, :user_groups, :configuration, :logger, :commit_messages
    attr_reader :gitolite_path

    def initializer(gitolite_path, override_configuration = nil, )
      @repos, @user_groups, @commit_messages = [], [], []
      @gitolite_path = gitolite_path
      @configuration = override_configuration || Configuration.new
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def open_repo(repo_name)
      repo_conf = Repo.new(repo_name, @logger)
      @repos << repo_conf
      repo_conf
    end

    def open_group(group_name)
      group_conf = UserGroup.new(group_name, @logger)
      @user_groups << group_conf
      group_conf
    end

    def add_user(username, rsa_pub_key, opts={})
      key_path = @configuration.user_key_path(username)

      if users_public_keys().include?(key_path)
        raise ::Gitolite::Duplicate, "Trying to create a user (#{user_object.git_username}) that exists already on gitolite server"
      end

      commit_file(key_path,rsa_pub_key, "Added RSA public key for user '#{username}'")

      key_path
    end

    def delete_user(username)
      key_path = @configuration.user_key_path(username)
      remove_file(key_path, "Removing RSA public key for user '#{username}'")
      username
    end

  private

    def gitolite_admin_repo()
      @gitolite_admin ||= FileAccess.new
    end

    def list_files_in_path(path)
      paths = gitolite_admin_repo.ls_r(path.split("/").size + 1, :files_only => true)
      match_regexp = Regexp.new("^#{path}")
      paths.select{ |p| p =~ match_regexp }
    end

    def users_public_keys()
      base_path = @configuration.keydir_path
      list_files_in_path(base_path)
    end

    def repo_config_file_paths()
      base_path = repo_config_relative_path
      ret_files_under_path(base_path)
    end

    def commit_file(file, content, commit_msg)
      @gitolite_admin.add_file(file, content)
      @gitolite_admin.commit(commit_msg)
      @commit_messages << commit_msg
    end

    def remove_file(file_path, commit_msg)
      @gitolite_admin.remove_file(file_path)
      @gitolite_admin.commit(commit_msg)
      @commit_messages << commit_msg
    end

  end
end