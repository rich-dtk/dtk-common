module Gitolite
  class Configuration

    attr_accessor :repositories_path, :user_groups_path, :keydir_path

    def initializer(
        repo_path_        = 'conf/repo-configs', 
        user_groups_path_ = 'conf/user-groups', 
        keydir_path_      = 'keydir'
      )
    
      @repositories_path = repo_path_
      @user_groups_path = user_groups_path_
      @keydir_path = keydir_path_
    end

    def user_key_path(username)
      "#{@keydir_path}/#{username}.pub"
    end
  end
end