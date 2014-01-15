
module Gitolite
  class Manager

    attr_accessor :repos, :user_groups, :configuration, :logger, :commit_messages
    attr_reader :gitolite_path

    def initialize(gitolite_path, override_configuration = nil)
      @repos, @user_groups, @commit_messages = [], [], []
      @gitolite_path = gitolite_path
      @configuration = override_configuration || Configuration.new
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def open_repo(repo_name)
      repo_conf = Repo.new(repo_name, @logger, @gitolite_path)
      @repos << repo_conf
      repo_conf
    end

    def open_group(group_name)
      group_conf = UserGroup.new(group_name, @logger, @gitolite_path)
      @user_groups << group_conf
      group_conf
    end

    def add_user(username, rsa_pub_key, opts={})
      key_path = @configuration.user_key_path(username)

      if users_public_keys().include?(key_path)
        raise ::Gitolite::Duplicate, "Trying to create a user (#{username}) that exists already on gitolite server"
      end

      commit_file(key_path,rsa_pub_key, "Added RSA public key for user '#{username}'")

      key_path
    end

    def remove_user(username)
      key_path = @configuration.user_key_path(username)

      unless users_public_keys().include?(key_path)
        raise ::Gitolite::NotFound, "User (#{username}) not found on gitolite server"
      end

      remove_file(key_path, "Removing RSA public key for user '#{username}'")
      username
    end

    def push()
      changed_repos  = @repos.select { |repo| repo.any_changes? }
      changed_groups = @user_groups.select { |ug| ug.any_changes? }

      unless (@commit_messages.empty? && changed_repos.empty? && changed_groups.empty?)
        gitolite_admin_repo().push()
      end
    end

  private

    def gitolite_admin_repo()
      @gitolite_admin ||= Git::FileAccess.new(@gitolite_path)
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

    def commit_file(file, content, commit_msg)
      gitolite_admin_repo().add_file(file, content)
      gitolite_admin_repo().commit(commit_msg)
      @commit_messages << commit_msg
    end

    def remove_file(file_path, commit_msg)
      gitolite_admin_repo().remove_file(file_path)
      gitolite_admin_repo().commit(commit_msg)
      @commit_messages << commit_msg
    end

  end
end