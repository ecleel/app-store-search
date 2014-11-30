require 'sinatra'

require 'csv'
require 'json'

require 'itunes-search-api'
require 'market_bot'

enable :inline_templates

get '/' do
  erb :index
end

post '/search' do
  query = request[:query]
  
  puts query

  itunes  = ITunesSearchAPI.search term: query, limit: 10, media: 'software', entity: 'software'
  play    = MarketBot::Android::SearchQuery.new(query).update.results

  market_names = %w(itunes play)
  unix_time = Time.now.to_i
  
  files = market_names.map { |mn| "tmp/#{query}_#{mn}_#{unix_time}.csv" }
  
  puts files
  
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
  
  files.to_json
end

__END__
@@ index
<html>
<head>
  <title>Search IPhone and Andriod Apps</title>
  <script src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
  <script>
  $(function() {
    
    $('#submit').click(function(){
      $.post('/search',
             {query: $('#query').val()},
             function(data){
               ary = JSON.parse(data);
               console.log(ary);
               console.log(ary[0])
                $('#result a:first').attr('href', ary[0]);
                $('#result a:last').attr('href', ary[1]);
      
                $('#result').show();
              }
            );
    });
  });
  </script>
</head>
<h1>Search Apps</h1>
<form action="/search" method="post" id="search">
  <input type="text" name="query" id='query'>
  <!-- <input type="submit"> -->
  <input type="button" id='submit' value='Submit'>
</form>
<div id='result' style="display:none;">
  <a href='javascript:void(0);'>
    <img src='images/csv_text.png' /><br/>
    Itunes
  </a>
  <a href='javascript:void(0);'>
    <img src='images/csv_text.png' /><br/>
    Play
  </a>
</div>
</html>