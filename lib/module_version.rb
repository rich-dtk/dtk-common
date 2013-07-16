module DtkCommon
  class ModuleVersion

    def self.string_has_version_format?(str)
      !!(str =~ /\A\d{1,2}\.\d{1,2}\.\d{1,2}\Z/)
    end

    def self.string_master_or_emtpy?(str)
      str.empty? || str.casecmp("master") || casecmp("default")
    end
  end
end