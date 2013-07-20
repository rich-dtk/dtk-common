module DtkCommon; module DSL; class FileParser
  class ComponentModuleRefs < self
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
          if v.kind_of?(InputHash) and v.only_has_keys?(:version,:remote_namespace,:namespace) and not v.empty?()
            parse_error = false
            new_el.merge_non_empty!(:version_info => v[:version], :remote_namespace => v[:remote_namespace]||v[:namespace])
          elsif v.kind_of?(String)
            parse_error = false
            new_el.merge_non_empty!(:version_info => v)
          elsif v.nil?
            parse_error = false
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

      def generate_hash(output_array)
        component_modules = output_array.inject(Hash.new) do |h,r|
          unless cmp_module = r[:component_module]
            raise Error.new("Missing field (:component_module)")
          end
          h.merge(cmp_module => Aux.hash_subset(r,OutputArrayToParseHashCols,:no_non_nil => true))
        end
        {:component_modules => component_modules} 
      end
      
      OutputArrayToParseHashCols = [{:version_info => :version},:remote_namespace]

    end

    class OutputArray < FileParser::OutputArray
      def self.keys_for_row()
        [:component_module,:version_info,:remote_namespace]
      end
      def self.has_required_keys?(hash_el)
        !hash_el[:component_module].nil?
      end
    end
  end
end; end; end

