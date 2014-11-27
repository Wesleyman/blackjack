require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'kjhfiebfcnvbmzfalfhjfhxcbmzbvwruquhqqer' 

helpers do
  # Cards is [['S', '9'], ['C', 'Q']] (i.e. nested arrays)
  # Curned into an array of values in the next line.
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    # Iterate through array of values only. 
    arr.each do |a|
      if a == "A"
        total += 11
      else
        # When to_i is called on a non integer, it is evaluated to 0.
        # So 'J', 'Q', 'K' in this case will be evaluated to 0.
        total += a.to_i == 0 ? 10 : a.to_i 
      end
  end

    #Correct for Aces
    # First select Ace values, count the number of times that 
    # -- Ace occurrs.
    arr.select{|element| element == "A"}.count.times do 
      break if total <= 21 
      total -= 10 
    end
    total
  end
end

before do
  @show_hit_or_stay_buttons = true 
end

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
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
 


erb :game 

end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) > 21 
    @error = "Sorry, it looks like you busted."
    @show_hit_or_stay_buttons = false
  end

  erb :game
end


post '/game/player/stay' do
  @success = "You have chosen to stay."
  @show_hit_or_stay_buttons = false
  erb :game 
end







