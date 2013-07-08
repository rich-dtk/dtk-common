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
      if adapter_name = AdaptersForMethods[name]
        execution_wrapper do
          adapter_instance = @adapters[adapter_name] ||= get_adapter_class(adapter_name).new(@repo_path)
          adapter_instance.send(name,*args,&block)
        end
      else
        super
      end
    end

    def execution_wrapper(&block)
      begin
        yield
       rescue ::DtkCommon::Error => e
        raise e
       rescue => e
        if e.respond_to?(:to_s)
          raise DtkCommon::Error.new(e.to_s)
        else
          raise e
        end
      end
    end
    
    def respond_to?(name)
      AdaptersForMethods.has_key(name)
    end

    def get_adapter_class(adapter_name)
      DynmamicLoader.load_and_return_adapter_class(:git_repo,adapter_name,:base_class => Adapter)
    end

    AdaptersForMethods = {
      :get_file_content => :rugged
    }
  end
end




