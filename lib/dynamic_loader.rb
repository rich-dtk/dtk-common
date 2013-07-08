require File.expand_path('common_patch',File.dirname(__FILE__))
module DtkCommon
  class DynmamicLoader
    def self.load_and_return_adapter_class(adapter_type,adapter_name,opts={})
      begin
        caller_dir = caller.first.gsub(/\/[^\/]+$/,"")
        Lock.synchronize{nested_require_with_caller_dir(caller_dir,"#{adapter_type}/adapters",adapter_name)}
      rescue LoadError
        raise Error.new("cannot find #{adapter_type} adapter (#{adapter_name})")
      end
      base_class = opts[:base_class] || DtkCommon.const_get(camel_case(adapter_type))
      base_class.const_get(camel_case(adapter_name))
    end

   private
    Lock = Mutex.new
    def self.nested_require_with_caller_dir(caller_dir,dir,*files_x)
      files = (files_x.first.kind_of?(Array) ? files_x.first : files_x) 
      files.each{|f|require File.expand_path("#{dir}/#{f}",caller_dir)}
    end
    def self.camel_case(x)
      Aux.snake_to_camel_case(x.to_s)
    end
  end
end

