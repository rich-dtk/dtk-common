module DTK
  module Common
    class SimpleHashObject < Hash
      def initialize(initial_val=nil,&block)
        block ? super(&block) : super()
        if initial_val
          replace(initial_val)
        end
      end
    end

    # require 'active_support/ordered_hash'
    # class SimpleOrderedHash < ::ActiveSupport::OrderedHash
    class SimpleOrderedHash < Hash
      def initialize(elements=[])
        super()
        elements = [elements] unless elements.kind_of?(Array)
        elements.each{|el|self[el.keys.first] = el.values.first}
      end
    
      #set unless value is nill
      def set_unless_nil(k,v)
        self[k] = v unless v.nil?
      end
    end

    class PrettyPrintHash < SimpleOrderedHash
      #field with '?' suffix means optioanlly add depending on whether name present and non-null in source
      #if block is given then apply to source[name] rather than returning just source[name]
      def add(model_object,*keys,&block)
        keys.each do |key|
          #if marked as optional skip if not present
          if key.to_s =~ /(^.+)\?$/
            key = $1.to_sym
            next unless model_object[key]
          end
          #special treatment of :id
          val = (key == :id ? model_object.id : model_object[key]) 
          self[key] = (block ? block.call(val) : val)
        end
        self
      end

      def slice(*keys)
        keys.inject(self.class.new){|h,k|h.merge(k => self[k])}
      end
    end
  end
end
