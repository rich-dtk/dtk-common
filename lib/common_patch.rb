#TODO: just putting in hooks for errors and logs
#need to figure out how to hook calling library's errors
require File.expand_path('auxiliary', File.dirname(__FILE__))
require File.expand_path('log', File.dirname(__FILE__))
module DtkCommon
  class Error < NameError
    def initialize(msg,name=nil)
      super(msg,name)
      end
  end
  class ErrorUsage < Error
  end
  Log = ::DTK::Log
  module Aux
    extend ::DTK::Common::AuxMixin
  end
end
