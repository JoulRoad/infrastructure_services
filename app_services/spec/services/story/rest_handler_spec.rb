require 'spec_helper'
require 'net/http'

describe Services::Story::RestHandler do
  let(:config) { { 'final_user_service_url' => 'http://example.com/' } }
  let(:fields_to_be_fetched) { ['story_title', 'username', 'story_tags'] }
  
  before do
    allow(ServicesConfig).to receive(:config).and_return(config)
  end

  describe '.fetch_stories_by_ids' do
    let(:story_ids) { ['67e3886010766513e7d38f9d', '67fe2fca1076655b4a856500'] }
    let(:query) { URI.encode("story/get_stories_by_id?story_ids=#{story_ids}") }
    let(:full_uri) { URI.parse(config['final_user_service_url']).merge!(query) }
    let(:http_double) { instance_double(Net::HTTP) }
    let(:request) { instance_double(Net::HTTP::Get) }
    
    before do
      allow(Net::HTTP::Get).to receive(:new).with(full_uri.request_uri).and_return(request)
      allow(Net::HTTP).to receive(:start).with(full_uri.host, full_uri.port).and_yield(http_double)
    end

    context 'when input is invalid' do
      it 'returns nil when story_ids is not an array' do
        result = described_class.fetch_stories_by_ids('not_an_array', fields_to_be_fetched)
        expect(result).to be_nil
      end

      it 'returns nil when story_ids is empty' do
        result = described_class.fetch_stories_by_ids([], fields_to_be_fetched)
        expect(result).to be_nil
      end
    end

    context 'when connection fails' do
      before do
        allow(http_double).to receive(:request).with(request).and_raise(Errno::ECONNREFUSED)
      end

      it 'returns an empty array' do
        result = described_class.fetch_stories_by_ids(story_ids, fields_to_be_fetched)
        expect(result).to eq([])
      end
    end

    context 'when response is not successful' do
      let(:response) { instance_double(Net::HTTPResponse, code: '404', body: '') }

      before do
        allow(http_double).to receive(:request).with(request).and_return(response)
      end

      it 'returns an empty array' do
        result = described_class.fetch_stories_by_ids(story_ids, fields_to_be_fetched)
        expect(result).to eq([])
      end
    end
  end

  describe '.fetch_story_by_id' do
    let(:story_id) { '67e3886010766513e7d38f9d' }
    let(:query) { "story/get_story_by_id?story_id=#{story_id}" }
    let(:rest_handler_instance) { instance_double('RestHandler') }
    
    before do
      allow(RestHandler).to receive(:new).with(url: config['final_user_service_url'], query: query).and_return(rest_handler_instance)
    end

    context 'when connection fails' do
      before do
        allow(rest_handler_instance).to receive(:send_get_call).with(0.5).and_raise(Errno::ECONNREFUSED)
      end

      it 'returns nil' do
        result = described_class.fetch_story_by_id(story_id, fields_to_be_fetched)
        expect(result).to be_nil
      end
    end

    context 'when response is empty' do
      before do
        allow(rest_handler_instance).to receive(:send_get_call).with(0.5).and_return(nil)
      end

      it 'returns nil' do
        result = described_class.fetch_story_by_id(story_id, fields_to_be_fetched)
        expect(result).to be_nil
      end
    end

    context 'when response is successful with data' do
      let(:raw_story) do
        {
          'story_title' => 'Pop of Color',
          'username' => 'ankita',
          'story_tags' => ['western', 'westernwear', 'toptrends', 'trending', 'trend'],
          'other_field' => 'should_not_be_included'
        }
      end

      let(:expected_result) do
        {
          'story_title' => 'Pop of Color',
          'username' => 'ankita',
          'story_tags' => ['western', 'westernwear', 'toptrends', 'trending', 'trend']
        }
      end

      before do
        allow(rest_handler_instance).to receive(:send_get_call).with(0.5).and_return(raw_story)
      end

      it 'returns the story with only requested fields' do
        result = described_class.fetch_story_by_id(story_id, fields_to_be_fetched)
        expect(result).to eq(expected_result)
      end
    end
  end
end