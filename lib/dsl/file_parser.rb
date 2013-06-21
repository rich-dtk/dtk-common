require 'singleton'
require 'json'
module DtkCommon
  module DSL             
    class FileParser
      def initialize(input_hash_class)
        @input_hash_class = input_hash_class
      end

      def self.parse_content(file_type,file_content,opts={})
        file_parser = Loader.file_parser(file_type,opts[:version])
        raw_hash_content = convert_json_content_to_hash(file_content)
        file_parser.parse_hash_content_aux(raw_hash_content)
      end

      def parse_hash_content_aux(raw_hash)
        parse_hash_content(input_form(raw_hash))
      end

      class OutputArray < Array
        def <<(hash_el)
          bad_keys = hash_el.keys - self.class.keys_for_row()
          unless bad_keys.empty?
            raise Error.new("Illegal keys being inserted in OutputArray (#{bad_keys.join(',')})")
          end
          super
        end
      end
      class OutputHash < SimpleHashObject
        def only_has_keys?(*only_has_keys)
          (keys() - only_has_keys).empty?
        end
        
        def merge_non_empty!(hash)
          each{|k,v| merge!(k => v) unless v.nil? or v.empty?}
          self
        end
      end

      class InputHash < SimpleHashObject
        #to provide autovification and use of symbol indexes
        def [](index)
          val = super(index.to_s)||{}
          (val.kind_of?(Hash) ? self.class.new(val) : val)
        end
      end

     private
      def input_form(raw_hash)
        @input_hash_class.new(raw_hash)
      end

      def self.convert_json_content_to_hash(json_file_content)
        begin 
          ::JSON.parse(json_file_content)
        rescue ::JSON::ParserError => e
          raise ErrorUsage::JSONParse.new(e.to_s)
        end
      end

      class Loader
        include Singleton
        def self.file_parser(file_type,version=nil)
          instance.file_parser(file_type,version)
        end

        def file_parser(file_type,version=nil)
          ret = (@loaded_types[file_type]||{})[version]
          return ret if ret
          unless FileTypes.include?(file_type)
            raise Error.new("Illegal file type (#{file_type})")
          end

          #load base if no versions loaded already
          if (@loaded_types[file_type]||{}).empty?
            base_path = "file_parser/#{file_type}"
            require File.expand_path(base_path,File.dirname(__FILE__))
          end

          version ||= default_version(file_type)
          path = "file_parser/#{file_type}/v#{version.to_s}/#{file_type}"
          require File.expand_path(path, File.dirname(__FILE__))

          base_class = FileParser.const_get(Aux.snake_to_camel_case(file_type.to_s))
          ret_class = base_class.const_get("V#{version.to_s}")
          input_hash_class = ret_class.const_get "InputHash"
          ret = ret_class.new(input_hash_class)
          (@loaded_types[file_type] ||= Hash.new)[version] = ret
          ret
        end
       private
        def initialize()
          @loaded_types = Hash.new
        end

        def default_version(file_type)
          FileTypeVesisonDefaults[file_type] || 1
        end
        FileTypes = 
          [
           :component_module_refs
          ]
        FileTypeVesisonDefaults = {
          :component_module_refs => 1
        }
      end
    end

    class ErrorUsage
      #when error is content does not have JSON
      class JSONParse < self
      end
      #when error is dtk content
      class DTKParse < ErrorUsage
      end
    end
  end
end
