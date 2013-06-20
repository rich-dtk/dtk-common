require 'singleton'
module DtkCommon
  module DSL             
    class FileParser
      def self.parse_content(file_type,file_content,opts={})
        file_parser = Loader.file_parser(file_type,opts[:version])
        hash_content = {} #TODO: stub
        pp file_parser.parse_hash_content(hash_content)
      end
      class Output
        class ArrayOutput < Array
          def <<(hash_el)
            bad_keys = hash_el.keys - self.class.keys_for_row()
            unless bad_keys.empty?
              raise Error.new("Illegal keys being inserted in ArrayOutput (#{bad_keys.join(',')})")
            end
            super
          end
        end
        class HashOutput < Hash
          def initialize(initial_val=nil)
            super()
            replace(initial_val) if initial_val
          end
        end
      end
     private
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
          ret = base_class.const_get("V#{version.to_s}").new
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
  end
end
