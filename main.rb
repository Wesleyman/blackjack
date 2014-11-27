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

  # ['H', '4'] (has two elements, suit and value)
  def card_image(card)

    suit = case card[0]

      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

  value = card[1]
  if ['J', 'Q', 'K', 'A'].include?(value)
    value = case card[1]
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
    end
  end

   "<img src='/images/cards/#{suit}_#{value}.jpg'class'card_image>"

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
if params[:player_name].empty?
  @error = "You must enter your name first."
  halt erb(:new_player)
end 
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

  player_total = calculate_total(session[:player_cards])
  if player_total == 21 
    @success = "Congratulations! #{session[:player_name]} hit blackjack!"
    @show_hit_or_stay_buttons = false
  elsif player_total > 21 
    @error = "Sorry, it looks like #{session[:player_name]} busted."
    @show_hit_or_stay_buttons = false
  end

  erb :game
end


post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_buttons = false

  # Decision tree.
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == 21 
    @error = "Sorry dealer hit blackjack."
    elsif dealer_total > 21 
      @success = "Congratulations, dealer busted. #{session[:player_name]} wins!"
    elsif dealer_total >= 17 
      # dealer stays
      redirect '/game/compare'
    else
      # dealer hits
      @show_dealer_hit_button = true 
    end

    erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer' 
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false 

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_total])
  if player_total < dealer_total
  @error = "Sorry you lost."
  elsif player_total > dealer_total
  @success = "You win!"
  else
  @success = "It's a tie!"    
  end

  erb :game
end







