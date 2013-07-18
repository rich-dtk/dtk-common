module DTK
  module Common
    require File.expand_path('require_first.rb', File.dirname(__FILE__))

    # we use sorting to establish deterministic behavior accross systems
    # Dir.glob will not return list of files in same order each time is run, which led to some bug being present
    # on some systems and not on the others
    file_list = Dir.glob("#{File.dirname(__FILE__)}/**/*.rb").sort { |a,b| a <=> b }

    file_list.each do |file|
      require file unless file.include?('dtk-common.rb') || file.include?('file_access/') || file.include?('require_first.rb') || file.include?('postgres.rb') || file.include?('rugged/')
    end
  end
end
