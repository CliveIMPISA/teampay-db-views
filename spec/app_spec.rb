require_relative 'spec_helper'
require_relative 'support/story_helpers'
require 'json'

describe 'TeamPay Stories' do
  include StoryHelpers

  describe 'Getting the root of the TeamPay Service' do
    it 'Should return ok' do
      get '/'
      last_response.must_be :ok?
      last_response.body.must_match(/welcome/i)
    end
  end

  describe 'Getting Team information' do
    it 'should return their Salary Information' do
      get '/api/v1/MIA.json'
      last_response.must_be :ok?
    end
    it 'should return 404 for unknown team' do
      get "/api/v1/#{random_str(20)}.json"
      last_response.must_be :not_found?
    end
  end

  describe 'TeamPayApp' do
    it "should return of two Phoenix players' salaries" do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = { teamname: ['PHO'],
               player_name: ['Archie Goodwin', 'Marcus Morris'] }
      post '/api/v1/check', body.to_json, header
      last_response.must_be :ok?
    end

    it 'should return 404 for unknown players' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = { teamname: [random_str(15)],
               player_name: [random_str(30)] }
      post '/api/v1/check', body.to_json, header
      last_response.must_be :not_found?
    end

    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)
      post '/api/v1/check', body, header
      last_response.must_be :bad_request?
    end
  end

  describe "should return of two Phoenix players' salaries" do
    it 'should find total salaries of the two players below' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body =  { teamname: ['PHO'],
                player_name: ['Archie Goodwin', 'Marcus Morris'] }
      post '/api/v1/check3', body.to_json, header
      last_response.must_be :ok?
    end
    it 'should return 404 for unknown users' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = { teamname: [random_str(15)], player_name: [random_str(30)] }
      post '/api/v1/check3', body.to_json, header
      last_response.must_be :not_found?
    end
    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)
      post '/api/v1/check3', body, header
      last_response.must_be :bad_request?
    end
  end

  describe "should return of two Phoenix players' salaries" do
    it 'should find total salaries of the two players below' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body =  { teamname: ['PHO'],
                player_name: ['Archie Goodwin', 'Marcus Morris'] }
      post '/api/v1/check2', body.to_json, header
      last_response.must_be :ok?
    end
    it 'should return 404 for unknown users' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = { teamname: [random_str(15)], player_name: [random_str(30)] }
      post '/api/v1/check2', body.to_json, header
      last_response.must_be :not_found?
    end
    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)
      post '/api/v1/check2', body, header
      last_response.must_be :bad_request?
    end
  end
end
