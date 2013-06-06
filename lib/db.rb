#TODO: facter into multiple files
require File.expand_path('auxiliary', File.dirname(__FILE__))
module DTK; module Common
  module ORMMixin
   private
    def db_adapter_class()
      DB::Adapter::Postgres
    end
  end
  module ORMClassMixin
    def migration_class()
      raise "Sequel dependency has been removed, contact Haris to refactor this! @migration_class"
      #::Sequel
    end
    def ORMModel()
      raise "Sequel dependency has been removed, contact Haris to refactor this! @ORMModel"
      #::Sequel::Model 
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
    def initialize(orm_instance)
      @orm_instance = orm_instance
    end

    def hash_form(keys_subset=nil)
      full_hash = values
      keys_subset ? Aux.hash_subset(full_hash,keys_subset) : full_hash
    end

    def _update(hash_values)
      @orm_instance.update(self.class.preprocess_hash_values(hash_values))
      # @orm_instance will have values that have been converted if needed
      @orm_instance.set_values(@orm_instance.values.merge(hash_values))
      self
    end

    def self._delete(hash_filter)
      unless hash_filter.keys == [:id]
        raise Error.new("Not implemented yet: delete filter other than providing id")
      end
      filter_ok?(hash_filter,:raise_error => true)
      unless element = orm_handle()[hash_filter]
        raise ErrorUsage.new("There is no object of type (#{class_name()}) with id (#{hash_filter[:id].to_s})")
      end
      element.delete()
    end
    
    def self._create(hash_values,opts={})
      convert_raw_record(orm_handle().create(preprocess_hash_values(hash_values)),opts)
    end

    def self._all(opts={})
      orm_handle().all().map{|raw_record|convert_raw_record(raw_record,opts)}
    end

    def self._where(filter,opts={})
      filter_ok?(filter,:raise_error => true)
      orm_handle().where(filter).map{|raw_record|convert_raw_record(raw_record,opts)}
    end

    def self.[](filter,opts={})
      filter_ok?(filter,:scalar_allowed => true,:raise_error => true)
      raw_row = orm_handle()[filter]
      raw_row && convert_raw_record(raw_row,opts)
    end

    def self.ret_if_exists_and_unique(filter,opts={})
      filter_ok?(filter,:raise_error => true)
      rows = _where(filter,opts)
      if rows.size == 1
        rows.first 
      elsif rows.size == 0
        if opts[:raise_error]
          raise ErrorUsage.new("Filter (#{pp_filter(filter)}) does not match any object of type #{object_type()}")
        end
      else # size > 1
        if opts[:raise_error] or opts[:raise_error_if_not_unique]
          raise ErrorUsage.new("Filter (#{pp_filter(filter)}) for object type #{object_type()} is ambiguous")
        end
      end
    end

   private
    def self._one_to_many(name, opts={}, &block)
      association_aux(:one_to_many,name,opts,&block)
    end
    def self._many_to_many(name, opts={}, &block)
      association_aux(:many_to_many,name,opts,&block)
    end
    def self._many_to_one(name, opts={}, &block)
      association_aux(:many_to_one,name,opts,&block)
    end

    def method_missing(name,*args,&block)
      pass_to_orm_instance(name) ? @orm_instance.send(name,*args,&block) : super
    end
    def respond_to?(name)
      pass_to_orm_instance(name)||super
    end

    def pass_to_orm_instance(name)
      @orm_instance.respond_to?(name)
    end

    def self.filter_ok?(filter,opts={})
      error_msg =
        if opts[:scalar_allowed] and filter.kind_of?(Fixnum)
        elsif opts[:scalar_allowed] and filter.kind_of?(String)
          #TODO: assumes that primary key is an integer 
          if not filter.to_s =~ /^[0-9]+$/
            "Ill-formed id: '#{filter}'"
          end
        elsif filter.kind_of?(Hash)
          #TODO: just picking out first one
          bad_key_field = filter.keys.find do |k| 
            (k.to_s =~ /^id$/ or k.to_s =~ /_id$/) and not filter[k].to_s =~ /^[0-9]+$/
          end
          if bad_key_field
            "Ill-formed id field (#{bad_key_field}): '#{filter[bad_key_field]}'"
          end
        else
          "Ill-formed filter (#{filter.inspect})"
        end
      if opts[:raise_error] and error_msg
        raise ErrorUsage.new(error_msg)
      end
      error_msg ? nil : true
    end

   public
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
      def association_aux(method,model_name,opts={},&block)
        model_class = Common::Aux.snake_to_camel_case(model_name.to_s).gsub(/s$/,"")
        assoc_class = "#{self.to_s.gsub(/::[^:]+$/,"")}::#{model_class}::#{model_class}"
        after_load_proc = proc do |x|
          if x.kind_of?(Array)
            x.map{|el|new(el)}
          else
            raise Error.new("Not implemented yet")
          end
        end
        sequel_opts_defaults = {
          :class => assoc_class,
          :after_load => after_load_proc
        }
        sequel_opts = sequel_opts_defaults.merge(opts)
        orm_handle().send(method,model_name,sequel_opts,&block)
      end

      def preprocess_hash_values(hash_values)
        return hash_values if (@json_fields||[]).empty?
        ret = hash_values.dup
        (@json_fields||[]).each do |jf|
          val = key = nil
          if ret[jf]
            val = ret[jf]
            key = jf
          elsif ret[jf.to_sym]
            val = ret[jf.to_sym]
            key = jf.to_sym
          end
          if key  
            ret[key] = convert_hash_to_json?(val)
          end
        end
        ret
      end
      public :preprocess_hash_values

      def extract_db_params(hash)
        Aux.hash_subset(hash,_columns())
      end

      def pp_filter(filter)
        filter.inspect
      end
      def object_type()
        _table_name()
      end

      def convert_raw_record(sequel_record,opts={})
        hash = sequel_record.values

        #TODO: simple processing that does not do merging
        (@json_fields||[]).each do |json_field|
          hash[json_field] = convert_json_to_hash?(hash[json_field])
        end

        if opts[:no_nulls]
          hash.each_key{|k|hash.delete(k) if hash[k].nil?}
        end

        if opts[:hash_form]
          hash
        else
          #through side effects sequel_record is changed
          new(sequel_record)
        end
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
        if name_s =~ /^_(.+$)/
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

