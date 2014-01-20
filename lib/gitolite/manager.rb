
require 'fileutils'

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

    def delete_repo(repo_name)
      file_path = @configuration.repo_path(repo_name)
      remove_file(file_path, "Deleting repo (#{repo_name}) from gitolite.")

      bare_repo_path = @configuration.bare_repo_path(repo_name)
      if File.directory?(bare_repo_path)
        FileUtils.rm_rf bare_repo_path
      end
      repo_name
    end

    def open_group(group_name)
      group_conf = UserGroup.new(group_name, @logger, @gitolite_path)
      @user_groups << group_conf
      group_conf
    end

    def create_user(username, rsa_pub_key, opts={})
      key_path = @configuration.user_key_path(username)

      if users_public_keys().include?(key_path)
        raise ::Gitolite::Duplicate, "Trying to create a user (#{username}) that exists already on gitolite server"
      end

      add_commit_file(key_path,rsa_pub_key, "Added RSA public key for user '#{username}'")

      key_path
    end

    def delete_user(username)
      key_path = @configuration.user_key_path(username)

      unless users_public_keys().include?(key_path)
        raise ::Gitolite::NotFound, "User (#{username}) not found on gitolite server"
      end

      remove_file(key_path, "Removing RSA public key for user '#{username}'")
      username
    end

    def remove_user_group(group_name)
      group_path = @configuration.user_group_path(group_name)

      unless user_group_list.include?(group_path)
        raise ::Gitolite::NotFound, "User group (#{group_name}) not found on gitolite server"
      end

      remove_file(key_path, "Removing user group (#{group_name})")
      group_name
    end

    def delete_user_group(group_name)
      path = @configuration.user_group_path(group_name)
      remove_file(path, "Remove user group (#{group_name}) from gitolite.")
      group_name
    end

    def list_repos()
      repo_names = repo_names_list()
      repo_names.map { |repo_name| { :repo_name => repo_name, :type => Repo.get_repo_type(repo_name) }}
    end

    def push()
      changed_repos  = @repos.select { |repo| repo.any_changes? }
      changed_groups = @user_groups.select { |ug| ug.any_changes? }

      unless (@commit_messages.empty? && changed_repos.empty? && changed_groups.empty?)
        changed_repos.each  { |repo| repo.commit_changes }
        changed_groups.each { |ug|   ug.commit_changes   }

        gitolite_admin_repo().push()
      end
    end

  private

    def gitolite_admin_repo()
      @gitolite_admin ||= Git::FileAccess.new(@gitolite_path)
    end

    def users_public_keys()
      base_path = @configuration.keydir_path
      list_files_in_path(base_path)
    end

    def user_group_list()
      base_path = @configuration.user_group_path
      list_files_in_path(base_path)
    end

    def repo_names_list()
      base_path = @configuration.repo_path
      repo_file_list = list_files_in_path(base_path)
      repo_file_list.collect { |r_file_name| extract_file_name(r_file_name, base_path, :conf) }
    end

    def add_commit_file(file, content, commit_msg)
      gitolite_admin_repo().add_file(file, content)
      gitolite_admin_repo().commit(commit_msg)
      @commit_messages << commit_msg
    end

    def remove_file(file_path, commit_msg)
      gitolite_admin_repo().remove_file(file_path)
      gitolite_admin_repo().commit(commit_msg)
      @commit_messages << commit_msg
    end


    class << self

      def repo_name_from_file_name(file_name, repo_file_path)
        if file_name =~ Regexp.new("^#{repo_file_path}/(.+)\.conf")
          $1
        else
          raise Error.new("File name not properly formed for repo config file name (#{file_name})")
        end
      end
    end

    def extract_file_name(full_path_name, file_path, file_extension)
      if file_name =~ Regexp.new("^#{full_path_name}/(.+)\.#{file_extension}")
        $1
      else
        raise ::Gitolite::ParseError.new("File name not properly formed (#{full_path_name}), expected match based on '#{file_path}/*.#{file_extension}'")
      end
    end

    def list_files_in_path(path)
      paths = gitolite_admin_repo.ls_r(path.split("/").size + 1, :files_only => true)
      match_regexp = Regexp.new("^#{path}")
      paths.select{ |p| p =~ match_regexp }
    end

  end
end