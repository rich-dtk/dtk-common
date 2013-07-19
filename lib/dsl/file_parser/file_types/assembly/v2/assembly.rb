module DtkCommon; module DSL; class FileParser
  class Assembly < self
    class OutputArray < FileParser::OutputArray
      def self.keys_for_row()
        [:assembly_name,:components]
      end
    end

    class V2 < self
      def parse_hash_content(input_hash)
        ret = OutputArray.new
        assembly_hash = OutputHash.new(
          :assembly_name => input_hash[:name],
          :components => Component.parse_hash_content(input_hash[:assembly]||{})                                       
        )
        ret << assembly_hash
        ret
      end

      class Component
        class OutputArray < FileParser::OutputArray
          def self.keys_for_row()
            [:component_name,:module_name,:node_name]
          end
        end

        def self.parse_hash_content(input_hash)
          ret = OutputArray.new
          input_hash.each_pair do |node_name,node_info|
            (node_info[:components]||{}).each_key do |mod_component_name|
              module_name,component_name = ret_module_and_component_names(mod_component_name)
              ret << OutputHash.new(:component_name => component_name,:module_name => module_name,:node_name => node_name)
            end
          end
          ret
        end
       private
        def self.ret_module_and_component_names(mod_component_name)
          if mod_component_name =~ /(^[^:]+)::([^:]+$)/
            [$1,$2]
          else
             mod_component_name
          end
        end
      end

    end
  end
end; end; end

