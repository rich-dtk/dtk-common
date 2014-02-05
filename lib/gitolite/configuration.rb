module Gitolite
  class Configuration

    attr_reader :repositories_path, :user_group_path, :keydir_path, :home_dir

    def initialize(
        repo_path_        = 'conf/repo-configs', 
        user_group_path_  = 'conf/group-defs', 
        keydir_path_      = 'keydir',
        home_dir_         = nil
      )
    
      @repositories_path = repo_path_
      @user_group_path = user_group_path_
      @keydir_path = keydir_path_
      @home_dir = home_dir_
    end

    def user_key_path(username)
      "#{@keydir_path}/#{username}.pub"
    end

    def user_group_path(group_name)
      "#{@user_group_path}/#{group_name}.conf"
    end

    def repo_path(repo_name)
      "#{@repositories_path}/#{repo_name}.conf"
    end

    def bare_repo_path(repo_name)
      "#{@home_dir}/repositories/#{repo_name}.git"
    end 
  end
end
