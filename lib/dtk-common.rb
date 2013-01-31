module DTK
  module Common
    require File.expand_path('require_first.rb', File.dirname(__FILE__))

    Dir.glob("#{File.dirname(__FILE__)}/**/*.rb") do |file|
      require file unless file.include?('dtk-common.rb') || file.include?('file_access/') || file.include?('require_first.rb')
    end
  end
end
