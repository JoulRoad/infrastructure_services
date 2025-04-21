require 'rails_helper'

RSpec.describe Services::Product::Aerospike, type: :module do
  let(:client_double) { instance_double(AerospikeGem::Client) }

  before do
    # Stub Aerospike client
    client_class = class_double('AerospikeGem::Client').as_stubbed_const
    allow(client_class).to receive(:new).and_return(client_double)
    # Reset memoized client
    described_class.instance_variable_set(:@client, nil)
  end

  describe '.client' do
    it 'memoizes the Aerospike client instance' do
      expect(AerospikeGem::Client).to receive(:new).once.and_return(client_double)
      first_call = described_class.client
      second_call = described_class.client
      expect(first_call).to eq(client_double)
      expect(second_call).to eq(client_double)
    end
  end

  describe '.fetch_products_by_ids' do
    let(:ids)     { ['21246997', '21356411'] }
    let(:price_interval) { '7d' }
    let(:bins) do
      [
        'static',
        "price_#{price_interval}",
        'qualityRating',
        'static_video',
        'o2o_video',
        'feedbackUpid'
      ]
    end
    let(:fields)  { ['name', 'qualityRating'] }

    let(:record1) do
      {
        'name'          => 'women solid tank top',
        'qualityRating' => '5.0'
      }
    end

    let(:record2) do
      {
        'name'          => 'women v neck solid regular top',
        'qualityRating' => '4.0'
      }
    end

    before do
      allow(client_double).to receive(:mget)
        .with(ids, 'upid_data', bins)
        .and_return([record1, record2])
    end

    it 'returns a hash mapping each id to its requested field values, with qualityRating wrapped in JSON' do
      result = described_class.fetch_products_by_ids(ids, bins, fields)

      expect(result).to eq({
        '21246997' => ['women solid tank top', '{"quality":"5.0"}'],
        '21356411' => ['women v neck solid regular top', '{"quality":"4.0"}']
      })
    end

    context 'when ids is blank' do
      let(:ids) { [] }

      it 'returns an empty hash without calling Aerospike' do
        expect(client_double).not_to receive(:mget)
        expect(described_class.fetch_products_by_ids(ids, bins, fields)).to eq({})
      end
    end

    context 'when Aerospike returns nil records' do
      before do
        allow(client_double).to receive(:mget)
          .with(ids, 'upid_data', bins)
          .and_return([nil, record2])
      end

      it 'returns nil values for missing records and processes others' do
        result = described_class.fetch_products_by_ids(ids, bins, fields)

        expect(result['21246997']).to eq([nil, nil])
        expect(result['21356411']).to eq(['women v neck solid regular top', '{"quality":"4.0"}'])
      end
    end
  end

  describe '.fetch_product_by_id' do
    let(:id)    { '21246997' }
    let(:price_interval) { '7d' }
    let(:bins) do
      [
        'static',
        "price_#{price_interval}",
        'qualityRating',
        'static_video',
        'o2o_video',
        'feedbackUpid'
      ]
    end
    let(:fields) { ['name', 'qualityRating'] }

    let(:record) do
      {
        'name'          => 'women solid tank top',
        'qualityRating' => '5.0'
      }
    end

    context 'when the record exists' do
      before do
        allow(client_double).to receive(:mget)
          .with([id], 'upid_data', bins)
          .and_return([record])
      end

      it 'returns the field values for the given id with qualityRating wrapped in JSON' do
        result = described_class.fetch_product_by_id(id, bins, fields)
        expect(result).to eq(['women solid tank top', '{"quality":"5.0"}'])
      end
    end

    context 'when the record is nil' do
      before do
        allow(client_double).to receive(:mget)
          .with([id], 'upid_data', bins)
          .and_return([nil])
      end

      it 'returns an array of nil values' do
        result = described_class.fetch_product_by_id(id, bins, fields)
        expect(result).to eq([nil, nil])
      end
    end
  end
end
