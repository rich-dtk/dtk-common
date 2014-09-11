require 'yaml'

module DTK
  module Common

    class ModuleParser

      MODULE_REFS_FILE   = 'module_refs.yaml'

      def initialize(module_name, module_namespace, repos_path, module_type=:service_module, is_server=false, dtk_username=nil)
        @module_name      = module_name
        @module_namespace = module_namespace
        @module_type      = module_type
        @repos_path       = repos_path
        @is_server        = is_server
        @dtk_username     = dtk_username
        @dependency_map   = nil
        @errors           = []
      end

      def calculate!()
        @dependency_map = recursive_calculation(@module_name, @module_namespace, @module_type)
        @dependency_map
      end

      #
      # Errors will return latest calculated changes
      #
      def errors()
        @dependency_map ||= recursive_calculation(@module_name, @module_namespace, @module_type)
        @errors
      end

    private

      def recursive_calculation(cm_name, cm_namespace, cm_type, chain_link = [])
        # if namespace not found user parent namespace (service namespace)
        cm_namespace = @module_namespace

        chain_identifier = "#{cm_namespace}::#{cm_name}(#{ModuleParser.resolve_module_type(cm_type)})"

        # !CHECK ERROR DETECTED CIRCUALAR DEPENDENCY
        if chain_link.include?(chain_identifier)
          return element(cm_name, cm_namespace, cm_type, chain_link, "Circular dependency detected for '#{chain_identifier}'!")
        end

        # STARTING PROCESSING (ID ADDED)
        chain_link << chain_identifier

        # READ COMPONENT MODULE FILE
        repo_path = ModuleParser.resolve_module_path(cm_type, cm_name, cm_namespace, @repos_path, @is_server, @dtk_username)

        begin
          module_refs = Gitolite::Git::FileAccess.new(repo_path).file_content(MODULE_REFS_FILE)
        rescue Exception => e
          return element(cm_name, cm_namespace, cm_type, chain_link, "Repo module '#{chain_identifier}' cannot be found")
        end

        # !CHECK ERROR MODEL DESCRIPTION IS MISSING
        unless module_refs
          return element(cm_name, cm_namespace, cm_type)
        end

        module_refs = YAML.load(module_refs)

        module_refs_cm = module_refs['component_modules']||[]
        module_refs_tm = module_refs['test_modules']||[]

        cm_results = []
        tm_results = []

        module_refs_cm.each do |cm_name, cm_values|
          cm_results << recursive_calculation(cm_name, cm_values['namespace'], :component_module, chain_link.dup)
        end

        module_refs_tm.each do |cm_name, cm_values|
          tm_results << recursive_calculation(cm_name, cm_values['namespace'], :test_module, chain_link.dup)
        end

        element = element(cm_name, cm_namespace, cm_type)
        element[:component_modules] = cm_results
        element[:test_modules] = tm_results

        element
      end

      def element(module_name, module_namespace, module_type, chain_info = [], error = nil)
        if error
          error_string =  error
          error_string += ", dependency location #{chain_info.join(' >> ')}" unless chain_info.empty?
          @errors << error_string
        end

        {
          :module_name => module_name,
          :module_namespace => module_namespace,
          :module_type => module_type,
          :location    => chain_info.empty? ? nil : chain_info.join(' >> '),
          :error => error
        }
      end

      def self.resolve_module_path(module_type, module_name, module_namespace, repos_path, is_server=false, dtk_username=nil)
        if is_server
          repo_name = "#{dtk_username}-#{module_namespace}-#{module_name}.git"
          repo_name = "#{resolve_module_type(module_type)}-#{repo_name}" unless module_type == :component_module
        else
          repo_name = "#{module_namespace}--#{resolve_module_type(module_type)}--#{module_name}.git"
        end

        File.join(repos_path, repo_name)
      end

      def self.resolve_module_type(module_type)
        case module_type
        when :service_module
          'sm'
        when :component_module
          'cm'
        when :test_module
          'tm'
        else
          raise "Not supported module type when resolving dependnecies #{module_type}"
        end
      end


    end
  end
end
