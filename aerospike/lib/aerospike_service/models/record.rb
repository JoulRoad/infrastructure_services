# frozen_string_literal: true

module AerospikeService
  module Models
    class Record
      attr_reader :key, :bins, :namespace

      def initialize(key:, bins:, namespace:)
        @key = key
        @bins = bins || {}
        @namespace = namespace
      end

      def [](bin)
        bins[bin.to_s]
      end

      def []=(bin, value)
        bins[bin.to_s] = value
      end

      def save(ttl: nil)
        AerospikeService.put(key: key, bins: bins, namespace: namespace, ttl: ttl)
      end

      def delete
        AerospikeService.delete(key: key, namespace: namespace)
      end

      def touch(ttl: nil)
        AerospikeService.touch(key: key, namespace: namespace, ttl: ttl)
      end

      def increment(bin:, value: 1)
        current_value = self[bin].to_i
        self[bin] = current_value + value
        save
        refresh
      end

      def refresh
        refreshed_bins = AerospikeService.get(key: key, namespace: namespace)
        @bins = refreshed_bins if refreshed_bins
        self
      end
    end
  end
end
