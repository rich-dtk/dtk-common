module DTK
  module Common
    Dir.glob('../lib/**/*.rb') do |file|
      require file unless file.include?('dtk-common.rb')
    end
  end
end
