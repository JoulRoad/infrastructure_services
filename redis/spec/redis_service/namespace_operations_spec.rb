# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples_spec'

RSpec.describe RedisService do
  shared_examples "namespaces" do |scenario|
    describe "namespaces" do
      it "properly isolates keys between namespaces" do
        RedisService.configure do |config|
          config.namespaces = {
            "users" => { prefix: "users" },
            "orders" => { prefix: "orders" }
          }
        end

        users = RedisService.namespace("users")
        orders = RedisService.namespace("orders")

        # Set keys in each namespace
        users.keys.set("123", { name: "Alice" })
        orders.keys.set("123", { product: "Gadget" })

        if scenario == :separate_urls
          # Sync namespace data
          users.with_read_connection do |redis|
            users.with_write_connection do |write_redis|
              redis.set("users:123", write_redis.get("users:123"))
            end
          end

          orders.with_read_connection do |redis|
            orders.with_write_connection do |write_redis|
              redis.set("orders:123", write_redis.get("orders:123"))
            end
          end
        end

        # Keys with the same ID in different namespaces should have different values
        expect(users.keys.get("123")).to eq({ "name" => "Alice" })
        expect(orders.keys.get("123")).to eq({ "product" => "Gadget" })
      end
    end
  end

  describe "with single URL for read/write" do
    include_examples "redis operations", :single_url
    include_examples "namespaces", :single_url
  end

  describe "with separate URLs for read/write" do
    include_examples "redis operations", :separate_urls
    include_examples "namespaces", :separate_urls
  end
end