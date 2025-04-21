# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe RedisService::Serialization do
  let(:namespace) { "serialization_test_#{Time.now.to_i}" }
  let(:read_url) { ENV.fetch('REDIS_READ_URL', 'redis://localhost:6379/14') }
  let(:write_url) { ENV.fetch('REDIS_WRITE_URL', 'redis://localhost:6379/15') }
  let(:read_pool) do
    ConnectionPool.new(size: 2, timeout: 5) do
      Redis.new(url: read_url)
    end
  end
  let(:write_pool) do
    ConnectionPool.new(size: 2, timeout: 5) do
      Redis.new(url: write_url)
    end
  end

  describe 'SerializerInterface' do
    let(:interface) { RedisService::Serialization::SerializerInterface.new }

    it 'requires implementing #serialize and #deserialize' do
      expect { interface.serialize('test') }.to raise_error(NotImplementedError)
      expect { interface.deserialize('{"test":"value"}') }.to raise_error(NotImplementedError)
    end
  end

  describe 'JsonSerializer' do
    let(:serializer) { RedisService::Serialization::JsonSerializer.new }

    describe '#serialize' do
      it 'handles nil' do
        expect(serializer.serialize(nil)).to be_nil
      end

      it 'handles primitive values' do
        expect(serializer.serialize('test')).to eq('"test"')
        expect(serializer.serialize(42)).to eq('42')
        expect(serializer.serialize(true)).to eq('true')
      end

      it 'handles arrays' do
        expect(serializer.serialize([1, 2, 3])).to eq('[1,2,3]')
      end

      it 'handles hashes' do
        expect(serializer.serialize({ a: 1, b: 2 })).to eq('{"a":1,"b":2}')
      end

      it 'handles complex nested structures' do
        complex = {
          name: 'Test',
          items: [1, 2, { key: 'value' }],
          metadata: {
            created_at: '2022-01-01',
            active: true
          }
        }
        expect(JSON.parse(serializer.serialize(complex))).to eq(JSON.parse(complex.to_json))
      end

      it 'raises SerializationError for non-serializable objects' do
        non_serializable = Object.new
        expect { serializer.serialize(non_serializable) }.to raise_error(RedisService::SerializationError)
      end
    end

    describe '#deserialize' do
      it 'handles nil' do
        expect(serializer.deserialize(nil)).to be_nil
      end

      it 'handles empty string' do
        expect(serializer.deserialize('')).to be_nil
      end

      it 'handles primitive values' do
        expect(serializer.deserialize('"test"')).to eq('test')
        expect(serializer.deserialize('42')).to eq(42)
        expect(serializer.deserialize('true')).to eq(true)
      end

      it 'handles arrays' do
        expect(serializer.deserialize('[1,2,3]')).to eq([1, 2, 3])
      end

      it 'handles hashes' do
        expect(serializer.deserialize('{"a":1,"b":2}')).to eq({ 'a' => 1, 'b' => 2 })
      end

      it 'handles complex nested structures' do
        json = '{"name":"Test","items":[1,2,{"key":"value"}],"metadata":{"created_at":"2022-01-01","active":true}}'
        expected = {
          'name' => 'Test',
          'items' => [1, 2, { 'key' => 'value' }],
          'metadata' => {
            'created_at' => '2022-01-01',
            'active' => true
          }
        }
        expect(serializer.deserialize(json)).to eq(expected)
      end

      it 'raises SerializationError for invalid JSON' do
        expect { serializer.deserialize('{"broken":') }.to raise_error(RedisService::SerializationError)
      end
    end
  end

  describe 'integration with RedisClient' do
    let(:client) do
      RedisService::Client::RedisClient.new(
        read_connection_pool: read_pool,
        write_connection_pool: write_pool,
        namespace: namespace
      )
    end

    before do
      # Clear both read and write databases before each test
      client.with_read_connection { |redis| redis.flushdb }
      client.with_write_connection { |redis| redis.flushdb }
    end

    after do
      # Clean up after each test
      client.with_read_connection { |redis| redis.flushdb }
      client.with_write_connection { |redis| redis.flushdb }
    end

    it 'serializes values when stored' do
      client.set('test_key', { test: 'value' })
      
      # Use write connection to retrieve the raw value since it was just written
      raw_value = client.with_write_connection do |redis|
        redis.get("#{namespace}:test_key")
      end
      
      expect(raw_value).to eq('{"test":"value"}')
    end

    it 'deserializes values when retrieved' do
      # Use write connection to set a raw value
      client.with_write_connection do |redis|
        redis.set("#{namespace}:test_key", '{"test":"value"}')
      end
      
      # Manually sync to read database to simulate replication
      client.with_read_connection do |redis|
        redis.set("#{namespace}:test_key", '{"test":"value"}')
      end
      
      expect(client.get('test_key')).to eq({ 'test' => 'value' })
    end

    it 'demonstrates read/write separation with serialized values' do
      # Write a serialized value
      client.set('complex_key', { nested: { data: [1, 2, 3] } })
      
      # Should not be available immediately on read connection
      expect(client.get('complex_key')).to be_nil
      
      # Manually sync to read database
      serialized_value = client.with_write_connection do |redis|
        redis.get("#{namespace}:complex_key")
      end
      
      client.with_read_connection do |redis|
        redis.set("#{namespace}:complex_key", serialized_value)
      end
      
      # Now it should be available
      expect(client.get('complex_key')).to eq({ 'nested' => { 'data' => [1, 2, 3] } })
    end

    it 'handles nil values' do
      expect(client.get('non_existent_key')).to be_nil
      client.set('nil_key', nil)
      
      # Manually sync nil value (which should be nil in Redis as well)
      client.with_read_connection do |redis|
        redis.set("#{namespace}:nil_key", client.with_write_connection { |r| r.get("#{namespace}:nil_key") })
      end
      
      expect(client.get('nil_key')).to be_nil
    end
  end
end 