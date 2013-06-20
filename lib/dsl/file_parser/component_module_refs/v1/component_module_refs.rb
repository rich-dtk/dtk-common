module DtkCommon; module DSL; class FileParser
  class ComponentModuleRefs
    class V1 < self
      def parse_hash_content(input_hash)
        ret = ArrayOutput.new
        component_modules = input_hash[:component_modules]
        if component_modules.empty?
          return ret
        else
          component_modules.each do |k,v|
            unless v.kind_of?(String)
              raise ErrorUsage::DTKParse.new("Term (#{v.inspect}) should be a string")
            end
            ret << HashOutput.new(:component_module => k, :version_info => v)
          end
        end
        ret
      end
    end
  end
end; end; end

