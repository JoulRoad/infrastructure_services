require 'spec_helper'

describe Services::Story::Fetcher do
  let(:story_ids) { ['67e3886010766513e7d38f9d', '67fe2fca1076655b4a856500'] }
  let(:bins) { ['default'] }
  let(:fields_to_be_fetched) { ['story_title', 'username', 'story_tags'] }
  
  describe '.fetch_stories_by_ids' do
    context 'when ids is blank' do
      it 'returns an empty array for nil input' do
        result = described_class.fetch_stories_by_ids(nil, bins, fields_to_be_fetched)
        expect(result).to eq([])
      end
      
      it 'returns an empty array for empty array input' do
        result = described_class.fetch_stories_by_ids([], bins, fields_to_be_fetched)
        expect(result).to eq([])
      end
    end
    
    context 'when all stories are found in cache' do
      let(:story_1) do
        {
          'story_title' => 'Pop of Color',
          'username' => 'ankita',
          'story_tags' => ['western', 'westernwear', 'toptrends', 'trending', 'trend']
        }
      end
      
      let(:story_2) do
        {
          'story_title' => 'Coming In Hot',
          'username' => 'Vaishali',
          'story_tags' => ['accessories', 'sets', 'jewellery', 'trending', 'trends', 'toptrends', 'cocktail', 'dailypost']
        }
      end
      
      let(:cached_stories_map) do
        {
          story_ids[0] => story_1,
          story_ids[1] => story_2
        }
      end
      
      before do
        allow(Services::Story::Aerospike).to receive(:fetch_stories_by_ids)
          .with(story_ids, bins, fields_to_be_fetched)
          .and_return(cached_stories_map)
      end
      
      it 'returns stories from cache without calling REST' do
        expect(Services::Story::RestHandler).not_to receive(:fetch_stories_by_ids)
        result = described_class.fetch_stories_by_ids(story_ids, bins, fields_to_be_fetched)
        expect(result).to eq([story_1, story_2])
      end
      
      context 'when stories are JSON strings' do
        let(:cached_stories_map) do
          {
            story_ids[0] => story_1.to_json,
            story_ids[1] => story_2.to_json
          }
        end
        
        it 'parses JSON strings before returning' do
          result = described_class.fetch_stories_by_ids(story_ids, bins, fields_to_be_fetched)
          expect(result).to eq([story_1, story_2])
        end
      end
    end
    
    context 'when some stories are not in cache' do
      let(:story_1) do
        {
          'story_title' => 'Pop of Color',
          'username' => 'ankita',
          'story_tags' => ['western', 'westernwear', 'toptrends', 'trending', 'trend']
        }
      end
      
      let(:story_2) do
        {
          'story_title' => 'Coming In Hot',
          'username' => 'Vaishali',
          'story_tags' => ['accessories', 'sets', 'jewellery', 'trending', 'trends', 'toptrends', 'cocktail', 'dailypost']
        }
      end
      
      let(:cached_stories_map) do
        {
          story_ids[0] => story_1
        }
      end
      
      before do
        allow(Services::Story::Aerospike).to receive(:fetch_stories_by_ids)
          .with(story_ids, bins, fields_to_be_fetched)
          .and_return(cached_stories_map)
      end
      
      context 'when REST handler returns stories' do
        before do
          allow(Services::Story::RestHandler).to receive(:fetch_stories_by_ids)
            .with([story_ids[1]], fields_to_be_fetched)
            .and_return([story_2])
        end
        
        it 'combines stories from cache and REST' do
          result = described_class.fetch_stories_by_ids(story_ids, bins, fields_to_be_fetched)
          expect(result).to eq([story_1, story_2])
        end
      end
      
      context 'when REST handler returns no stories' do
        before do
          allow(Services::Story::RestHandler).to receive(:fetch_stories_by_ids)
            .with([story_ids[1]], fields_to_be_fetched)
            .and_return([])
        end
        
        it 'returns only stories from cache' do
          result = described_class.fetch_stories_by_ids(story_ids, bins, fields_to_be_fetched)
          expect(result).to eq([story_1])
        end
      end
    end
  end
  
  describe '.get_story_by_id' do
    let(:story_id) { '67e3886010766513e7d38f9d' }
    
    context 'when id is blank' do
      it 'returns nil' do
        result = described_class.get_story_by_id(nil, bins, fields_to_be_fetched)
        expect(result).to be_nil
      end
      
      it 'returns nil for empty string' do
        result = described_class.get_story_by_id('', bins, fields_to_be_fetched)
        expect(result).to be_nil
      end
    end
    
    context 'when story is found in cache' do
      let(:story_data) do
        {
          'story_title' => 'Pop of Color',
          'username' => 'ankita',
          'story_tags' => ['western', 'westernwear', 'toptrends', 'trending', 'trend']
        }.to_json
      end
      
      before do
        allow(Services::Story::Aerospike).to receive(:fetch_story_by_id)
          .with(story_id, bins, fields_to_be_fetched)
          .and_return(story_data)
      end
      
      it 'returns parsed story data from cache without calling REST' do
        expect(Services::Story::RestHandler).not_to receive(:fetch_story_by_id)
        result = described_class.get_story_by_id(story_id, bins, fields_to_be_fetched)
        expect(result).to eq(JSON.parse(story_data))
      end
    end
    
    context 'when story is not found in cache' do
      before do
        allow(Services::Story::Aerospike).to receive(:fetch_story_by_id)
          .with(story_id, bins, fields_to_be_fetched)
          .and_return(nil)
      end
      
      context 'when REST handler returns the story' do
        let(:story_data) do
          {
            'story_title' => 'Pop of Color',
            'username' => 'ankita',
            'story_tags' => ['western', 'westernwear', 'toptrends', 'trending', 'trend']
          }
        end
        
        before do
          allow(Services::Story::RestHandler).to receive(:fetch_story_by_id)
            .with(story_id, fields_to_be_fetched)
            .and_return(story_data)
        end
        
        it 'returns story data from REST' do
          result = described_class.get_story_by_id(story_id, bins, fields_to_be_fetched)
          expect(result).to eq(story_data)
        end
      end
      
      context 'when REST handler returns no story' do
        before do
          allow(Services::Story::RestHandler).to receive(:fetch_story_by_id)
            .with(story_id, fields_to_be_fetched)
            .and_return(nil)
        end
        
        it 'returns an empty hash' do
          result = described_class.get_story_by_id(story_id, bins, fields_to_be_fetched)
          expect(result).to eq({})
        end
      end
    end
  end
end