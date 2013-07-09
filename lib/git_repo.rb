require File.expand_path('common_patch',File.dirname(__FILE__))
require File.expand_path('dynamic_loader',File.dirname(__FILE__))
#TODO: this will eventually replace the grit_adapter classes
module DtkCommon
  class GitRepo
    class Adapter 
    end

    def initialize(repo_path)
      @repo_path = repo_path
      @adapters = Hash.new
    end

   private
    def method_missing(name,*args,&block)
     if adapter_name = get_adapter_name(name)
        execution_wrapper do
          adapter_instance = @adapters[adapter_name] ||= get_adapter_class(adapter_name).new(@repo_path)
          adapter_instance.send(name,*args,&block)
        end
      else
        super
      end
    end

    def respond_to?(name)
      super(name) or AdaptersForMethods.has_key(name)
    end

    def execution_wrapper(&block)
      begin
        yield
       rescue => e 
        Log.error(([e.to_s]+e.backtrace).join("\n"))
        error = (e.kind_of?(::DtkCommon::Error) ? e : ::DtkCommon::Error.new(e.to_s))
        raise error
      end
    end
    
    def get_adapter_class(adapter_name)
      DynmamicLoader.load_and_return_adapter_class(:git_repo,adapter_name,:base_class => Adapter)
    end

    def get_adapter_name(method_name)
      ret = Array(AdaptersForMethods[method_name]||[]).find do |adapter_name|
        condition = AdapterConditions[adapter_name]
        condition.nil? or condition.call()
      end
      ret || raise(Error.new("Cannot find applicable adapter for method (#{method_name})"))
    end

    #for each hash value form is scalar or array of adapters to try in order
    AdaptersForMethods = {
      :get_file_content => :rugged
    }

    NailedRuggedVersion = '0.17.0.b7'

    AdapterConditions = {
      :rugged => proc{!::Gem::Specification::find_all_by_name('rugged',::Gem::Requirement.new(NailedRuggedVersion)).empty?}
    }
  end
end




