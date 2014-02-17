module DTK
  module Common
    def self.r8_require_common(path)
      require File.expand_path(path, File.dirname(__FILE__))
    end

    def self.is_gem_installed?(gem_name)
      begin
        # if no exception gem is found
        gem gem_name
        return true
      rescue Gem::LoadError
        return false
      end
    end
  end
end

