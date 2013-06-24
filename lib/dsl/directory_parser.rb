module DtkCommon
  module DSL
    class DirectoryParser
      require File.expand_path("directory_parser/linux",File.dirname(__FILE__))
      require File.expand_path("directory_parser/git",File.dirname(__FILE__))

      def initialize(directory_type)
        unless @file_info = file_info(directory_type)
          raise Error.new("Illegal directory type (#{directory_type})")
        end
        @directory_type = directory_type
      end

      def parse_directory(file_type=nil)
        pruned_file_info = 
          if file_type
            if match = @file_info.find{|r|r[:file_type] == file_type}
              pruned_file_info << match
            else
              raise Error.new("Illegal file type (#{file_type}) for directory_type (#{directory_type})")
            end
          else
            @file_info
          end
        #instantiate any rel_path_pattern
        pruned_file_instances  = instantiate_rel_path_patterns(pruned_file_info)
        pruned_file_instances.each do |r|
          file_content = get_content(r[:rel_path])
          pp FileParser.parse_content(r[:file_type],file_content)
        end
      end
     private
      def file_info(directory_type)
        DirectoryTypeFiles[directory_type]
      end
      def instantiate_rel_path_patterns(rel_file_info)
        ret = Array.new
        all_files_from_root = nil
        rel_file_info.each do |r|
          if rel_path = r[:rel_path]
            ret << r
          else
            rel_path_pattern = r[:rel_path_pattern]
            
            (all_files_from_root || all_files_from_root()).each do |f|
              if f =~ rel_path_pattern
                file_key = $1
                ret << {:rel_path => f, :file_type => r[:file_type], :key => file_key}
              end
            end
          end
        end
        ret
      end
      #TODO: may [put version info here too
      DirectoryTypeFiles = {
        :service_module => 
        [
         {:rel_path => "global_module_refs.json", :file_type => :component_module_refs},
         {:rel_path_pattern => /^assemblies\/([^\/]+)\/assembly\.json$/, :file_type => :assembly_dsl}
        ]
      }
    end
  end
end
