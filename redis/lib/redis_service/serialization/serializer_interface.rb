# frozen_string_literal: true

module RedisService
  module Serialization
    # Interface for serializers following the Interface Segregation Principle
    class SerializerInterface
      def serialize(object)
        raise NotImplementedError, "#{self.class} must implement #serialize"
      end

      def deserialize(string)
        raise NotImplementedError, "#{self.class} must implement #deserialize"
      end
    end
  end
end 