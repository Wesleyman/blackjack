require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'kjhfiebfcnvbmzfalfhjfhxcbmzbvwruquhqqer' 

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do 
  erb :new_player
end

post '/new_player' do 
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  # deck
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '9', 'A']
  session[:deck] = suits.product(values).shuffle
  # deal cards
  #   dealer cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  #   player cards


erb :game 

end








