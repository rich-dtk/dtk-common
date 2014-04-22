
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
      repo_conf = Repo.new(repo_name, @configuration, @logger, @gitolite_path)
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

    # this should be depracated
    def create_user(username, rsa_pub_key, rsa_pub_key_name)
      key_name = "#{username}@#{rsa_pub_key_name}"
      key_path = @configuration.user_key_path(key_name)

      if users_public_keys().include?(key_path)
        raise ::Gitolite::Duplicate, "Public key (#{rsa_pub_key_name}) already exists for user (#{username}) on gitolite server"
      end

      add_commit_file(key_path,rsa_pub_key, "Added public key (#{rsa_pub_key_name}) for user (#{username}) ")

      key_path
    end

    def create_user_depracated(username, rsa_pub_key)
      create_user(username, rsa_pub_key, 'default')
    end

    def delete_user(username)
      key_path = @configuration.user_key_path(username)

      has_there_been_deletion = remove_public_keys_for_user!(username)

      unless has_there_been_deletion
        raise ::Gitolite::NotFound, "User (#{username}) not found on gitolite server"
      end

      username
    end

    def add_pub_key!(username, rsa_pub_key_name, rsa_pub_key)
      file_name = "#{username}@#{rsa_pub_key_name}"
      key_path  = @configuration.user_key_path(file_name)

      if users_public_keys().include?(key_path)
        raise ::Gitolite::Duplicate, "Duplicate public key (#{rsa_pub_key_name}) for user (#{username})"
      end

      add_commit_file(key_path, rsa_pub_key, "Added RSA public key (#{file_name}) for user (#{username})")
      file_name
    end

    def remove_pub_key!(username, rsa_pub_key_name)
      file_name = "#{username}@#{rsa_pub_key_name}"
      key_path  = @configuration.user_key_path(file_name)

      unless users_public_keys().include?(key_path)
        raise ::Gitolite::NotFound, "Public key (#{rsa_pub_key_name}) for user (#{username}) not found"
      end

      remove_file(key_path, "Remove public key (#{rsa_pub_key_name}) for user (#{username})")
      true
    end

    def delete_user_group!(group_name)
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

    # only to help with migration, to be deleted later TODO: Delete
    # Depracated: To be removed 
    def migrate_to_multiple_pub_keys()
      all_pub_keys = users_public_keys()
      base_path    = @configuration.keydir_path

      puts "Starting migration of PUB keys from old format to new! (This can take a while)"
      all_pub_keys.each do |pub_key_path|
        # skip git pub or already migrated key
        unless pub_key_path.match(/.*git.pub$/) || pub_key_path.include?('@')
          file_name = extract_file_name(pub_key_path,base_path,:pub)
          pub_content = gitolite_admin_repo().file_content(pub_key_path)

          # delete_user
          remove_file(pub_key_path, "Migrating user ('#{file_name}') to new annotation, temporary removing user")

          # create user
          create_user_depracated(file_name, pub_content)
        end
      end
      puts "End migration of pub keys"
      require 'pp'
      pp users_public_keys
      puts "--------------- END ---------------"
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

    def extract_file_name(full_path_name, file_path, file_extension)
      if full_path_name =~ Regexp.new("^#{file_path}/(.+)\.#{file_extension}")
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

    def remove_public_keys_for_user!(username)
      all_pub_keys = users_public_keys()
      base_path    = @configuration.keydir_path
      is_deleted   = false

      all_pub_keys.each do |pub_key_path|
        file_name = extract_file_name(pub_key_path,base_path,:pub)

        # looking only at pub keys will '@' in their names
        if file_name.include?('@')
          files_username, files_pub_name = file_name.split('@')

          # e.g. for user 'haris' we remove haris@home.pub, haris@work.pub
          if files_username && files_username.eql?(username)
            remove_file(pub_key_path, "Remove public key (#{files_pub_name}) for user (#{username})")
            is_deleted = true
          end
        end
      end
      
      is_deleted
    end

    def number_of_public_keys_for_user(username)
      all_pub_keys = users_public_keys()
      base_path    = @configuration.keydir_path

      return all_pub_keys.count do |pub_key_path|
        file_name = extract_file_name(pub_key_path,base_path,:pub)
        (file_name.eql?(username) || file_name.match(/^#{username}@/))
      end
    end

  end
end