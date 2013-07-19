require File.expand_path('auxiliary', File.dirname(__FILE__))
require File.expand_path('log', File.dirname(__FILE__))
require File.expand_path('hash_object', File.dirname(__FILE__))
require File.expand_path('errors', File.dirname(__FILE__))
module DtkCommon
  module DSL    

    #TODO: just putting in hooks for errors and logs
    #need to figure out how to hook calling library's errors
    Error = ::DTK::Error
    ErrorUsage = ::DTK::ErrorUsage

    Log = ::DTK::Log
    SimpleHashObject = ::DTK::Common::SimpleHashObject
    module Aux
      extend ::DTK::Common::AuxMixin
    end

    require File.expand_path('dsl/directory_parser', File.dirname(__FILE__))
    require File.expand_path('dsl/file_parser', File.dirname(__FILE__))
  end
end




