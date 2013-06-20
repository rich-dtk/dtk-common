module DtkCommon
  module DSL             
    class Parser
      def self.parse_file(file_type,file_content,opts={})
        file_parser_class = ret_file_parser_class(file_type,opts[:version])
      end
     private
      def self.ret_file_parser_class(file_type,version=nil)
        version ||= ret_default_version(file_type)
      end
      def self.ret_default_version(file_type)
        FileTypeVesisonDefaults[:component_module_refs] || 1
      end
      FileTypeVesisonDefaults = {
        :component_module_refs => 1
      }
      FileTypes = FileTypeVersionDefaults.keys 
    end
  end
end; end



