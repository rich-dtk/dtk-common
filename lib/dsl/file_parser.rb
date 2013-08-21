require 'singleton'
require 'json'
require File.expand_path('../hash_object',File.dirname(__FILE__))

module DtkCommon
  module DSL             
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
        base_path = "#{BaseDirForFileTypes}/#{file_type}"
        #if (@loaded_types[file_type]||{}).empty?
        #   require File.expand_path(base_path,File.dirname(__FILE__))
        #end

        version ||= default_version(file_type)
        path = "#{base_path}/v#{version.to_s}/#{file_type}"
        require File.expand_path(path, File.dirname(__FILE__))

        base_class = FileParser.const_get(Aux.snake_to_camel_case(file_type.to_s))
        ret_class = base_class.const_get("V#{version.to_s}")
        input_hash_class = ret_class.const_get "InputHash"
        ret = ret_class.new(input_hash_class)
        (@loaded_types[file_type] ||= Hash.new)[version] = ret
        ret
      end
      BaseDirForFileTypes = "file_parser/file_types"
     private
      def initialize()
        @loaded_types = Hash.new
      end

      def default_version(file_type)
        FileTypeVesisonDefaults[file_type] || 1
      end
      FileTypes = 
        [
         :component_module_refs,
         :assembly
        ]
      FileTypeVesisonDefaults = {
        :component_module_refs => 1,
        :assembly => 2
      }
    end
    class FileParser
      def initialize(input_hash_class)
        @input_hash_class = input_hash_class
      end

      def self.implements_method?(method_name)
        [:parse_content,:generate_hash].include?(method_name)
      end

      def self.parse_content(file_type,file_content,opts={})
        ret = OutputArray.new
        # if there is no content (nil) return empty array as if content was empty
        return ret unless file_content
        file_parser = Loader.file_parser(file_type,opts[:version])
        raw_hash_content = convert_json_content_to_hash(file_content,opts[:file_path])

        return raw_hash_content if raw_hash_content.is_a?(ErrorUsage::DSLParsing::JSONParsing)

        file_parser.parse_hash_content_aux(raw_hash_content)
      end

      def parse_hash_content_aux(raw_hash)
        parse_hash_content(input_form(raw_hash))
      end

      def self.generate_hash(file_type,output_array,opts={})
        file_parser = Loader.file_parser(file_type,opts[:version])
        file_parser.generate_hash(output_array)
      end

      class OutputArray < Array
        def <<(hash_el)
          bad_keys = hash_el.keys - self.class.keys_for_row()
          unless bad_keys.empty?
            raise Error.new("Illegal keys being inserted in OutputArray (#{bad_keys.join(',')})")
          end
          super
        end

        def +(output_obj)
          if output_obj.kind_of?(OutputArray)
            super
          elsif output_obj.kind_of?(OutputHash)
            super(OutputArray.new(OutputHash))
          elsif output_obj.nil?
            self
          else
            raise Error.new("Unexpected object type (#{output_obj.class})")
          end
        end

        #can be overwritten
        def self.has_required_keys?(hash_el)
          (keys_for_row() - hash_el.keys?).nil?
        end

      end
      class OutputHash < ::DTK::Common::SimpleHashObject
        def merge_non_empty!(hash)
          hash.each{|k,v| merge!(k => v) unless v.nil? or v.empty?}
          self
        end

        def +(output_obj)
          if output_obj.kind_of?(OutputArray)
            OutputArray.new(self) + output_obj
          elsif output_obj.kind_of?(OutputHash)
            merge(output_obj)
          elsif output_obj.nil?
            self
          else
            raise Error.new("Unexpected object type (#{output_obj.class})")
          end
        end
      end

      class InputHash < Hash
        #to provide autovification and use of symbol indexes
        def initialize(hash=nil)
          super()
          return unless hash
          replace_el = hash.inject(Hash.new) do |h,(k,v)|
            processed_v = (v.kind_of?(Hash) ? self.class.new(v) : v)
            h.merge(k =>  processed_v)
          end
          replace(replace_el)
        end

        def [](index)
          val = super(internal_key_form(index)) || {}
          (val.kind_of?(Hash) ? self.class.new(val) : val)
        end
        def only_has_keys?(*only_has_keys)
          (keys() - only_has_keys.map{|k|internal_key_form(k)}).empty?
        end
       private
        def internal_key_form(key)
          key.to_s
        end
      end

     private
      def input_form(raw_hash)
        @input_hash_class.new(raw_hash)
      end

      def self.convert_json_content_to_hash(json_file_content, file_path=nil)

        ret = Hash.new
        if json_file_content.empty?
          return ret
        end

        begin 
          ::JSON.parse(json_file_content)
        rescue ::JSON::ParserError => e
          # raise ErrorUsage::JSONParse.new(e.to_s)
          return ErrorUsage::DSLParsing::JSONParsing.new("JSON parsing error #{e.to_s} in file", file_path)
        end
      end

    end

    class ErrorUsage < Error
      #when error is content does not have JSON
      # class JSONParse < self
      #   def initialize(base_json_error,file_path=nil)
      #     super(err_msg(base_json_error,file_path))
      #   end
      #   private
      #   def err_msg(base_json_error,file_path=nil)
      #     # file_ref = file_path && " in file (#{file_path})"
      #     # "JSON parsing error#{file_ref}: #{base_json_error}"
      #     "#{base_json_error}: #{file_path}"
      #   end
      # end

      class DSLParsing < self
        def initialize(base_json_error,file_path=nil)
          super(err_msg(base_json_error,file_path))
        end
        private
        def err_msg(base_json_error,file_path=nil)
          # file_ref = file_path && " in file (#{file_path})"
          # "JSON parsing error#{file_ref}: #{base_json_error}"
          "#{base_json_error}: #{file_path}"
        end

        class JSONParse < self
        end
      end

      #when error is dtk content
      class DTKParse < self
      end
    end
  end
end
