require 'rubygems'
require 'sinatra'



use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'kjhfiebfcnvbmzfalfhjfhxcbmzbvwruquhqqer' 


BLACKJACK          = 21 
DEALER_MIN_HIT     = 17
INITIAL_POT_AMOUNT = 500

helpers do
  # Cards is [['S', '9'], ['C', 'Q']] (i.e. nested arrays)
  # Turned into an array of values in the next line.
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
      break if total <= BLACKJACK 
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

 def winner!(msg)
  @play_again = true 
  @show_hit_or_stay_buttons = false
  # Winner condition.
  session[:player_pot] = session[:player_pot] + session[:player_bet]
  @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
 end

  def loser!(msg)
    @play_again = true 
    @show_hit_or_stay_buttons = false
    # Loser condition.
     session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser = "<strong>#{session[:player_name]} loses!</strong> #{msg}"
   end

  def tie!(msg)
    @play_again = true 
    @show_hit_or_stay_buttons = false
    @winner = "<strong>It's a tie!</strong> #{msg}"
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

# new_player route.
get '/new_player' do

# Ensures player has money at the beginning of the game.   
session[:player_pot] = INITIAL_POT_AMOUNT
  erb :new_player
end

post '/new_player' do
if params[:player_name].empty?
  @error = "You must enter your name first."
  halt erb(:new_player)
end 
  session[:player_name] = params[:player_name]
  # When new game is initialized, player is routed to bet.
  redirect '/bet'
end

# bet route.
get '/bet' do
  # clears current amount on the bet page.
  session[:player_bet] = nil  
  erb :bet
end

post '/bet' do
  # All values submitted from a form come in as strings, so call to_i so as to compare
  # -- to another integer. 

  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:erb)
  # No need to call to_i on player_pot here becuase it's already.
  # -- set as such above.   
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount should be less than what you have ($#{session[:player_pot]}) "
    halt erb(:erb)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

# game route.
get '/game' do
  session[:turn] = session[:player_name]

  # Create a deck and put it in sesson.
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
  if player_total == BLACKJACK 
    winner! ("#{session[:player_name]} hit blackjack!")
  elsif player_total > BLACKJACK 
    loser!("It looks like #{session[:player_name]} busted at #{player_total}.")
  end

  erb :game, layout: false
end


post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  # Decision tree.
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK 
    loser!("Dealer hit blackjack.")
    elsif dealer_total > BLACKJACK 
      winner!("Dealer busted at #{dealer_total}.")
    elsif dealer_total >= DEALER_MIN_HIT 
      # dealer stays
      redirect '/game/compare'
    else
      # dealer hits
      @show_dealer_hit_button = true 
    end

     erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer' 
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false 

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stays at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stays at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and dealer stayed and they have a tie of #{player_total}.")   
  end

   erb :game, layout: false
end

get '/game_over' do 
  erb :game_over
end







