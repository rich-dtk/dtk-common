require 'restclient'
require 'json'
module DTK
  module Common
    module ResponseTokens
      StatusOK = "ok"
      StatusNotok = "notok"
      DataField = "data"
      StatusField = "status"
      ErrorsField = "errors"
      ValidationField = "validation"
      ErrorsSubFieldCode = "code"
      GenericError = "error"
    end

    class Response < Hash
      include ResponseTokens
      def initialize(hash={})
        super()
        replace(hash)
      end
      def ok?()
        self[StatusField] == StatusOK
      end

      def validation_response?
        !self[ValidationField].nil?
      end

      def validation_message
        self[ValidationField]['message']
      end

      def error_message
        self["errors"] ? (self["errors"].map { |e| e["message"]}).join(', ') : nil
      end

      def validation_actions
        return self[ValidationField]['actions_needed']
      end

      def data(*data_keys)
        data = self[DataField]
        case data_keys.size
         when 0 then data
         when 1 then data && data[internal_key_form(data_keys.first)]
         else data_keys.map{|key|data && data[internal_key_form(key)]}.compact
        end
      end

      def data_hash_form(*data_keys)
        ret = Hash.new
        unless data = self[DataField]
          return ret
        end

        if data_keys.size == 0
          data.inject(Hash.new){|h,(k,v)|h.merge(external_key_form(k) => v)}
        else
          data_keys.each do |k|
            if v = data[internal_key_form(k)]
              ret.merge!(external_key_form(k) => v)
            end
          end
          ret
        end
      end

      def set_data(*data_values)
        self[DataField]=data_values
      end

      def data_ret_and_remove!(*data_keys)
        data = data()
        data_keys.map{|key|data.delete(internal_key_form(key))}
      end

      def add_data_value!(key,value)
        data()[key.to_s] = value
        self
      end

      def internal_key_form(key)
        key.to_s
      end
      def external_key_form(key)
        key.to_sym
      end
      private :internal_key_form,:external_key_form

      module ErrorMixin
        def ok?()
          false
        end
      end

      class Error < self
        include ErrorMixin
        def initialize(hash={})
          super(hash)
        end
      end

      class RestClientWrapper 
        class << self
          include ResponseTokens
          def get_raw(url,opts={},&block)
            error_handling(opts) do
              raw_response = ::RestClient::Resource.new(url,opts).get()
              block ? block.call(raw_response) : raw_response
            end
          end
        
          def get(url,opts={})
            get_raw(url,opts){|raw_response|Response.new(json_parse_if_needed(raw_response))}
          end

          def post_raw(url,body={},opts={},&block)
            error_handling(opts) do
              raw_response = ::RestClient::Resource.new(url,opts).post(body)
              block ? block.call(raw_response) : raw_response
            end
          end
        
          def post(url,body={},opts={})
            post_raw(url,body,opts){|raw_response|Response.new(json_parse_if_needed(raw_response))}
          end

          def json_parse_if_needed(item)
            item.kind_of?(String) ? JSON.parse(item) : item
          end
         private

          def error_handling(opts={},&block)            
            begin
              block.call 
            rescue ::RestClient::ServerBrokeConnection,::RestClient::Forbidden,::RestClient::InternalServerError,::RestClient::RequestTimeout,RestClient::Request::Unauthorized, Errno::ECONNREFUSED => e
              error_response({ErrorsSubFieldCode => RestClientErrors[e.class.to_s]||GenericError},opts)
            rescue Exception => e
              error_response({ErrorsSubFieldCode => e.class.to_s},opts)
            end
          end 

          def error_response(error_or_errors,opts={})
            errors = error_or_errors.kind_of?(Hash) ? [error_or_errors] : error_or_errors
            (opts[:error_response_class]||Error).new(StatusField => StatusNotok, ErrorsField => errors)
          end
          
          RestClientErrors = {
            "RestClient::Forbidden" => "forbidden",
            "RestClient::ServerBrokeConnection" => "broken",
            "RestClient::Request::Unauthorized" => "unauthorized",
            "RestClient::InternalServerError" => "internal_server_error",
            "RestClient::RequestTimeout" => "timeout",
            "Errno::ECONNREFUSED" => "connection_refused"
          }
        end
      end
    end
  end
end
