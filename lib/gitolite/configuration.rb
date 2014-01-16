module Gitolite
  class Configuration

    attr_accessor :repositories_path, :user_group_path, :keydir_path

    def initialize(
        repo_path_        = 'conf/repo-configs', 
        user_group_path_  = 'conf/user-groups', 
        keydir_path_      = 'keydir'
      )
    
      @repositories_path = repo_path_
      @user_group_path = user_group_path_
      @keydir_path = keydir_path_
    end

    def user_key_path(username)
      "#{@keydir_path}/#{username}.pub"
    end

    def user_group_path(group_name)
      "#{@user_group_path}/#{group_name}.conf"
    end
  end
end