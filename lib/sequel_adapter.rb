require 'sequel'
module DTK; module Common
  class SequelAdapter 
    require File.expand_path('sequel_adapter/db_adapter/postgres',File.dirname(__FILE__))
    class DB
      def initialize(db_params)
        @db = db_adapter_class().new(db_params)
      end
     private
      def method_missing(name,*args,&block)
        @db.respond_to?(name) ? @db.send(name,*args,&block) : super
      end
      def respond_to?(name)
        @db.respond_to?(name)||super
      end

      def db_adapter_class()
        Postgres
      end
    end
  end
end; end
