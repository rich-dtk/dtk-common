module DTK; module Common
  module DBandModelMixin
   private
    def db_adapter_class()
      DB::Adapter::Postgres
    end
  end
  module DBandModelClassMixin
    def migration_class()
      ::Sequel
    end
  end

  class DB
    include DBandModelMixin
    extend DBandModelClassMixin

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
    include DBandModelMixin
    extend DBandModelClassMixin
    def self.migration(&block)
      migration_class().migration(&block)
    end
  end
end; end

