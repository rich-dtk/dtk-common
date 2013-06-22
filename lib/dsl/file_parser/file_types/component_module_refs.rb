module DtkCommon; module DSL
  class FileParser
    class ComponentModuleRefs < self
      class OutputArray < FileParser::OutputArray
        def self.keys_for_row()
          [:component_module,:version_info,:remote_namespace]
        end
        def self.has_required_keys?(hash_el)
          !!(hash_el[:component_module] and (hash_el[:version_info] or hash_el[:remote_namespace]))
        end
      end
    end
  end
end; end

