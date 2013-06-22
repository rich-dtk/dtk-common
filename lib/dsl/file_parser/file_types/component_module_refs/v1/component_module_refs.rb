module DtkCommon; module DSL; class FileParser
  class ComponentModuleRefs
    class V1 < self
      def parse_hash_content(input_hash)
        ret = OutputArray.new
        component_modules = input_hash[:component_modules]
        if component_modules.empty?
          return ret
        end

        component_modules.each do |component_module,v|
          new_el = OutputHash.new(:component_module => component_module)
          parse_error = true
          if v.kind_of?(InputHash) and v.only_has_keys?(:version,:remote_namespace) and not v.empty?()
            parse_error = false
            new_el.merge_non_empty!(:version_info => v[:version], :remote_namespace => v[:remote_namespace])
          elsif v.kind_of?(String)
            parse_error = false
            new_el.merge_non_empty!(:version_info => v)
          end
          if parse_error
            err_msg = (parse_error.kind_of?(String) ? parse_error : "Ill-formed term (#{v.inspect})")
            raise ErrorUsage::DTKParse.new(err_msg)
          else
            ret << new_el
          end
        end
        ret
      end

    end
  end
end; end; end

