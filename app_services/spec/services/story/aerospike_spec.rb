require 'spec_helper'

describe Services::Story::Aerospike do
  let(:aerospike_client) { instance_double("AerospikeGem::Client") }
  let(:bins) { ["default"] }
  
  let(:story_1_id) { "67e3886010766513e7d38f9d" }
  let(:story_2_id) { "67fe2fca1076655b4a856500" }
  
  let(:story_1_data) do
    {
      "story_title" => "Pop of Color",
      "uuid" => "5c8ea4717083883eb50b9ba4",
      "story_tags" => ["western", "westernwear", "toptrends", "trending", "trend"],
      "username" => "ankita",
      "name" => "ankita Manot"
    }
  end
  
  let(:story_2_data) do
    {
      "story_title" => "Coming In Hot",
      "uuid" => "657192eefd1d3c10d4fe9684",
      "story_tags" => ["accessories", "sets", "jewellery", "trending", "trends", "toptrends", "cocktail", "dailypost"],
      "username" => "Vaishali",
      "name" => "Vaishali Bisht"
    }
  end
  
  before do
    allow(AerospikeGem::Client).to receive(:new).and_return(aerospike_client)
  end
  
  describe '.client' do
    it 'returns an Aerospike client instance' do
      client = Services::Story::Aerospike.client
      expect(client).to eq(aerospike_client)
    end
    
    it 'caches the client instance' do
      expect(AerospikeGem::Client).to receive(:new).once
      Services::Story::Aerospike.client
      Services::Story::Aerospike.client
    end
  end
  
  describe '.fetch_stories_by_ids' do
    context 'when ids is blank' do
      it 'returns an empty hash' do
        result = Services::Story::Aerospike.fetch_stories_by_ids([], bins, [])
        expect(result).to eq({})
      end
      
      it 'returns an empty hash when nil' do
        result = Services::Story::Aerospike.fetch_stories_by_ids(nil, bins, [])
        expect(result).to eq({})
      end
    end
    
    context 'when fetching multiple stories' do
      let(:ids) { [story_1_id, story_2_id] }
      let(:fields_to_be_fetched) { ["story_title", "username"] }
      
      before do
        allow(aerospike_client).to receive(:mget).with(ids, "stories", bins).and_return([story_1_data, story_2_data])
      end
      
      it 'fetches stories from Aerospike' do
        expect(aerospike_client).to receive(:mget).with(ids, "stories", bins)
        Services::Story::Aerospike.fetch_stories_by_ids(ids, bins, fields_to_be_fetched)
      end
      
      it 'returns only the requested fields' do
        result = Services::Story::Aerospike.fetch_stories_by_ids(ids, bins, fields_to_be_fetched)
        expected = {
          story_1_id => ["Pop of Color", "ankita"],
          story_2_id => ["Coming In Hot", "Vaishali"]
        }
        expect(result).to eq(expected)
      end
    end
    
    context 'when some stories are missing' do
      let(:ids) { [story_1_id, "non_existent_id"] }
      let(:fields_to_be_fetched) { ["story_title", "username"] }
      
      before do
        allow(aerospike_client).to receive(:mget).with(ids, "stories", bins).and_return([story_1_data, nil])
      end
      
      it 'filters out missing stories' do
        result = Services::Story::Aerospike.fetch_stories_by_ids(ids, bins, fields_to_be_fetched)
        expected = { story_1_id => ["Pop of Color", "ankita"] }
        expect(result).to eq(expected)
      end
    end
  end
  
  describe '.fetch_story_by_id' do
    let(:fields_to_be_fetched) { ["story_title", "username", "name"] }
    
    context 'when the story exists' do
      before do
        allow(aerospike_client).to receive(:get).with(story_1_id, "stories", bins).and_return(story_1_data)
      end
      
      it 'fetches the story from Aerospike' do
        expect(aerospike_client).to receive(:get).with(story_1_id, "stories", bins)
        Services::Story::Aerospike.fetch_story_by_id(story_1_id, bins, fields_to_be_fetched)
      end
      
      it 'returns the requested fields' do
        result = Services::Story::Aerospike.fetch_story_by_id(story_1_id, bins, fields_to_be_fetched)
        expect(result).to eq(["Pop of Color", "ankita", "ankita Manot"])
      end
    end
    
    context 'when the story does not exist' do
      before do
        allow(aerospike_client).to receive(:get).with("non_existent_id", "stories", bins).and_return(nil)
      end
      
      it 'returns nil' do
        result = Services::Story::Aerospike.fetch_story_by_id("non_existent_id", bins, fields_to_be_fetched)
        expect(result).to be_nil
      end
    end
    
    context 'when the story is blank' do
      before do
        allow(aerospike_client).to receive(:get).with(story_1_id, "stories", bins).and_return({})
      end
      
      it 'returns nil' do
        result = Services::Story::Aerospike.fetch_story_by_id(story_1_id, bins, fields_to_be_fetched)
        expect(result).to be_nil
      end
    end
  end
end