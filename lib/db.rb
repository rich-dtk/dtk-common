#TODO: facter into multiple files
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
      ### overrides to straight passing to orm
      def _create(hash_values)
        hash_values_x = hash_values
        (@json_fields||[]).each do |jf|
          val = key = nil
          if hash_values_x[jf]
            val = hash_values_x[jf]
            key = jf
          elsif hash_values_x[jf.to_sym]
            val = hash_values_x[jf.to_sym]
            key = jf.to_sym
          end
          if key and 
              hash_values_x[key] = convert_hash_to_json?(val)
          end
        end
        orm_handle().create(hash_values_x)
      end

      def _all(opts={})
        orm_handle().all().map{|raw_record|convert_raw_record(raw_record,opts)}
      end
      def convert_raw_record(sequel_record,opts={})
        ret = sequel_record.values
        if opts[:no_nulls]
          ret.each_key{|k|ret.delete(k) if ret[k].nil?}
        end
        #TODO: simple processing that does not do mergeing
        (@json_fields||[]).each do |json_field|
          ret[json_field] = convert_json_to_hash?(ret[json_field])
        end
        ret
      end
      #### END: overrides to straight passing to orm

      ##methods to deal with JSON fields
      require 'json'

      def JSONField(field_name)
        (@json_fields ||= Array.new) << field_name
      end
      #converts from json form if it is in json form
      def convert_json_to_hash?(possible_json_val)
        ret = possible_json_val
        return ret unless possible_json_val.kind_of?(String)
        begin
          ret = JSON.parse(possible_json_val)
        rescue
        end
        ret
      end
      def convert_hash_to_json?(possible_hash)
        ret = possible_hash
        return ret unless possible_hash.kind_of?(Hash)
        JSON.generate(possible_hash)
      end

      ##END: methods to deal with JSON fields

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

