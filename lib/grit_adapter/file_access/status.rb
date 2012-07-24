module DTK::Common; class GritAdapter; class FileAccess
  module StatusMixin
    def status()
      chdir_and_checkout do
        Status.new(@grit_repo.status)
      end
    end

    class Status < Hash
      def initialize(grit_status_obj)
        super()
        [:added,:deleted,:changed,:untracked].each do |file_state|
#          paths_with_file_state = grit_status_obj.send(file_state).map{|info|info[0]} 
          paths_with_file_state = grit_status_obj.send(file_state).map{|info|info[1].path} 
          self[file_state] = paths_with_file_state unless paths_with_file_state.empty?
        end
      end
    end
  end                                         
end; end; end
