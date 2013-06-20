require File.expand_path('auxiliary', File.dirname(__FILE__))
module DtkCommon
  module DSL    
    #TODO: need to figure out how to hook calling library's errors
    #stub
    class Error < NameError
    end
    module Aux
      extend DTK::Common::AuxMixin
    end
    require File.expand_path('dsl/file_parser', File.dirname(__FILE__))
    #TODO: built on file_parser is functions that understands directory structure and knows which files have which semantic types
  end
end
require 'pp'
DtkCommon::DSL::FileParser.parse_content(:component_module_refs,{})




