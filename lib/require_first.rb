module DTK
  module Common
    def self.r8_require_common(path)
      require File.expand_path(path, File.dirname(__FILE__))
    end
  end
end

