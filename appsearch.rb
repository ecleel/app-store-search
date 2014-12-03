require 'sinatra'

require 'csv'
require 'json'

require 'itunes-search-api'
require 'market_bot'

enable :inline_templates

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

post '/search' do
  query = request[:query]

  itunes  = ITunesSearchAPI.search term: query, limit: 200, media: 'software', entity: 'software'
  play    = MarketBot::Android::SearchQuery.new(query).update.results

  market_names = %w(itunes play)
  unix_time = Time.now.to_i
  
  files = market_names.map { |mn| "tmp/#{query}_#{mn}_#{unix_time}.csv" }
  
  [itunes, play].each_with_index do |store_results, idx|
    CSV.open(files[idx], "w") do |csv|
      store_results.each_with_index do |hash, idx|
        if idx == 0
          csv << hash.keys
        else
          csv << hash.values
        end
      end
    end
  end
  
  files.map! {|file| file.gsub('tmp/', 'file/') }
  files.to_json
end

get '/file/*' do |file|
  send_file "tmp/" + file
end
