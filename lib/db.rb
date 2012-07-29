module DTK; module Common
  module ORMMixin
   private
    def db_adapter_class()
      DB::Adapter::Postgres
    end
  end
  module ORMClassMixin
    def migration_class()
      ::Sequel
    end
    def ORMModel() 
      ::Sequel::Model 
    end
  end

  class DB
    include ORMMixin
    extend ORMClassMixin

    def initialize(db_params)
      @db = db_adapter_class().create(db_params)
    end
   private
    def method_missing(name,*args,&block)
      @db.respond_to?(name) ? @db.send(name,*args,&block) : super
    end
    def respond_to?(name)
      @db.respond_to?(name)||super
    end

    class Adapter
      require File.expand_path('db/adapter/sequel/postgres',File.dirname(__FILE__))
    end            
  end

  class Model
    include ORMMixin
    extend ORMClassMixin
    class << self
      def inherited(subclass)
        super
        subclass.class_eval("class #{class_name(subclass)} < ORMModel();end")
      end

      def migration(&block)
        migration_class().migration(&block)
      end

      def respond_to?(name)
        (!!respond_to_mapped_name(name))||super
      end
     private
      #complexity with orm_handle arises beacuse sequel does not seem to allow abstract class to inherit to ::Sequel::Model
      def method_missing(name,*args,&block)
        mapped_name = respond_to_mapped_name(name)
        mapped_name ? orm_handle().send(mapped_name,*args,&block) : super
      end

      def respond_to_mapped_name(name)
        name_s = name.to_s
        if name_s == "[]"
          "[]".to_sym
        elsif name_s =~ /^_(.+$)/
          mapped_name = $1.to_sym
          orm_handle().respond_to?(mapped_name) && mapped_name
        else
          nil
        end
      end

      def orm_handle()
        #TODO: check if safe to use return @orm_handle if @orm_handle
        const_get class_name()
      end
      def class_name(klass=nil)
        (klass||self).to_s =~ /::([^:]+$)/;$1
      end
    end
  end
end; end

