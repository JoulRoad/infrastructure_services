# frozen_string_literal: true

require "json"

module RedisService
  module Serialization
    # JSON serializer with Single Responsibility for JSON serialization
    class JsonSerializer < SerializerInterface
      def serialize(object)
        return nil if object.nil?
        JSON.generate(object)
      rescue => e
        raise SerializationError, "Error serializing object to JSON: #{e.message}"
      end

      def deserialize(string)
        return nil if string.nil? || string.empty?
        JSON.parse(string)
      rescue => e
        raise SerializationError, "Error deserializing JSON: #{e.message}"
      end
    end
  end
end 