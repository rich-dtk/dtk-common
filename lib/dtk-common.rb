module DTK
  module Common

    # we are refering to dtk-common-repo folder here
    POSSIBLE_COMMON_CORE_FOLDERS = ['dtk-common-repo','dtk-common-core']

    require File.expand_path('require_first.rb', File.dirname(__FILE__))

    # this gem needs dtk-common-repo to work we load it
    unless is_gem_installed?('dtk-common-repo')
      dtk_common_core_folder = POSSIBLE_COMMON_CORE_FOLDERS.find do |folder|
        path = File.join(File.dirname(__FILE__),'..','..',folder)
        File.directory?(path)
      end

      if dtk_common_core_folder
        require File.expand_path("../../#{dtk_common_core_folder}/lib/dtk-common-repo.rb", File.dirname(__FILE__))
      else
        raise "Not able to find 'dtk-common-core' gem!"
      end
    end


    # we use sorting to establish deterministic behavior accross systems
    # Dir.glob will not return list of files in same order each time is run, which led to some bug being present
    # on some systems and not on the others
    file_list = Dir.glob("#{File.dirname(__FILE__)}/**/*.rb").sort { |a,b| a <=> b }

    file_list.each do |file|
      require file unless file.include?('dtk-common.rb') || file.include?('file_access/') || file.include?('require_first.rb') || file.include?('postgres.rb') || file.include?('rugged/')
    end
  end
end
