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

      def data(*data_keys)
        data = self[DataField]
        case data_keys.size
         when 0 then data
         when 1 then data[internal_key_form(data_keys.first)]
         else data_keys.map{|key|data[internal_key_form(key)]}
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
      private :internal_key_form

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
            rescue ::RestClient::InternalServerError,::RestClient::RequestTimeout,Errno::ECONNREFUSED => e
              error_response({ErrorsSubFieldCode => RestClientErrors[e.class.to_s]||GenericError},opts)
            rescue Exception => e
              error_response({ErrorsSubFieldCode => GenericError},opts)
            end
          end 

          def error_response(error_or_errors,opts={})
            errors = error_or_errors.kind_of?(Hash) ? [error_or_errors] : error_or_errors
            (opts[:error_response_class]||ResponseError).new(StatusField => StatusNotok, ErrorsField => errors)
          end
          
          RestClientErrors = {
            "RestClient::InternalServerError" => "internal_server_error",
            "RestClient::RequestTimeout" => "timeout",
            "Errno::ECONNREFUSED" => "connection_refused"
          }
        end
      end
    end
  end
end
