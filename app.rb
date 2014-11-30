require 'sinatra/base'
require 'sinatra'
require 'nbasalaryscrape'
require 'json'
require_relative 'model/income'
require 'haml'
require 'sinatra/flash'
require 'httparty'

# nbasalaryscrape service
class TeamPayApp < Sinatra::Base
  enable :sessions
  register Sinatra::Flash
  use Rack::MethodOverride

  configure :production, :development do
    enable :logging
  end

  configure :development do
    set :session_secret, "something"    # ignore if not using shotgun in development
  end

  API_BASE_URI = 'http://localhost:9292'

  helpers do
    def get_team(teamname)
      var = SalaryScraper::BasketballReference.new
      return nil if teamname == 'default'
      begin
        var.to_array_of_hashes(teamname.upcase)
      rescue
        nil
      end
    end

    def get_team2(teamname)
      var = SalaryScraper::BasketballReference.new
      begin
        var.to_array_of_hashes(teamname.upcase)
      rescue
        halt 404
      else
        var.to_array_of_hashes(teamname.upcase)
      end
    end

    def get_team_players(teamname)
      begin
        team = get_team(teamname)
        team_players = []
        team.each do |player_salary_scrape|
          team_players << player_salary_scrape['Player']
        end
      rescue
        halt 404
      end
      team_players
    end

    def player_salary_data(teamname, player_name)

      begin
        salary_scrape = get_team2(teamname[0])
        player_scrape = []
        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            player_scrape <<  data_row  if data_row['Player'] == each_player
          end
        end
      rescue
        halt 404
      else
        player_scrape
      end
    end

    def one_total(data_row, each_player)
      player_scrape, fullpay = 0, []
      player_scrape +=  parse_money(data_row['2014-15'])
      player_scrape +=  parse_money(data_row['2015-16'])
      player_scrape +=  parse_money(data_row['2016-17'])
      player_scrape +=  parse_money(data_row['2017-18'])
      player_scrape +=  parse_money(data_row['2018-19'])
      player_scrape +=  parse_money(data_row['2019-20'])
      fullpay << { 'player' => each_player,
                   'fullpay' => back_to_money(player_scrape) }
      fullpay
    end

    def player_total_salary(teamname, player_name)
      players = []
      return nil if teamname[0] == 'default'

      begin
        salary_scrape = get_team(teamname[0])
        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            if data_row['Player'] == each_player
              players << one_total(data_row, each_player)
            end
          end
        end
      rescue
        nil
      end

        return if players.length==0
      players
    end

    def player_total_salary2(teamname, player_name)
      players = []
      begin
        salary_scrape = get_team(teamname[0])
        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            if data_row['Player'] == each_player
              players << one_total(data_row, each_player)
            end
          end
        end
      rescue
        halt 404
      end
      players
    end

    def two_players_salary_data(teamname, player_name)
      return nil if teamname == 'default'
      player_scrape = []
      begin
        salary_scrape = get_team(teamname[0])

        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            player_scrape << diff_total(data_row, each_player) if data_row['Player'] == each_player
          end
        end
        make_salary_comparisons(player_scrape)
      rescue
        nil
      else
        make_salary_comparisons(player_scrape)
      end
    end

    def two_players_salary_data2(teamname, player_name)
      return nil if teamname == 'default'
      player_scrape = []
      begin
        salary_scrape = get_team(teamname[0])

        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            player_scrape << diff_total(data_row, each_player) if data_row['Player'] == each_player
          end
        end
        make_salary_comparisons(player_scrape)
      rescue
        halt 404
      else
        make_salary_comparisons(player_scrape)
      end
    end

    def make_salary_comparisons(player_scrape)
      if player_scrape[0]['fullpay'] > player_scrape[1]['fullpay']
        diff = player_scrape[0]['fullpay'] - player_scrape[1]['fullpay']
        return_string = "#{player_scrape[0]['player']} makes #{back_to_money(diff)} more than #{player_scrape[1]['player']} "
      elsif player_scrape[1]['fullpay'] > player_scrape[0]['fullpay']
        diff = player_scrape[1]['fullpay'] - player_scrape[0]['fullpay']
        return_string = "#{player_scrape[1]['player']} makes #{back_to_money(diff)} more than #{player_scrape[0]['player']} "
      else
        return_string = "#{player_scrape[1]['player']} and #{player_scrape[0]['player']} makes the same salary (#{back_to_money(player_scrape[0]['fullpay'])})"
      end
      return_string
    end

    def diff_total(data_row, each_player)
      player_scrape = 0
      player_scrape += parse_money(data_row['2014-15'])
      player_scrape += parse_money(data_row['2015-16'])
      player_scrape += parse_money(data_row['2016-17'])
      player_scrape += parse_money(data_row['2017-18'])
      player_scrape += parse_money(data_row['2018-19'])
      player_scrape += parse_money(data_row['2019-20'])
      fullpay = { 'player' => each_player,
                  'fullpay' => player_scrape }
      fullpay
    end

    def parse_money(money)
      data = money.gsub(/[$,]/, '$' => '', ',' => '')
      data.to_i
    end

    def back_to_money(data)
      money = "$#{data.to_s.reverse.gsub(/...(?=.)/, '\&,').reverse}"
      money
    end

    def current_page?(path = ' ')
      path_info = request.path_info
      path_info += ' ' if path_info == '/'
      request_path = path_info.split '/'
      request_path[1] == path
    end
  end

  get '/' do
    haml :home
  end

  get '/salary' do
    @teamname = params[:teamname]
    if @teamname
      redirect "/salary/#{@teamname}"
      return nil
    end

    haml :salary
  end

  get '/salary/:teamname' do
    @teamname = params[:teamname]
    @salary = get_team(@teamname)

    if @salary.nil?
      flash[:notice] = 'Please select team from list' if @salary.nil?
      redirect '/salary'
    end
    haml :salary
  end

  get '/individualsalaries' do
    @action = :create
    haml :individualsalaries
  end

  post '/individualsalaries' do
    request_url = "#{API_BASE_URI}/api/v1/check3"

    playername2 = params[:playername2]
    teamname = params[:teamname]
    playername1 = params[:playername1]
    params_h = {
          playername2: playername2,
          teamname: teamname,
          playername1: playername1
    }

    options =  {
                  body: params_h.to_json,
                  headers: { 'Content-Type' => 'application/json' }
               }

    result = HTTParty.post(request_url, options)

    if (result.code != 200)
      flash[:notice] = 'Players not found! Ensure that team and player names are spelled correctly. '
      redirect '/individualsalaries'
      return nil
    end

    id = result.request.last_uri.path.split('/').last
    session[:result] = result.to_json
    session[:playername2] = playername2
    session[:playername1] = playername1
    session[:teamname] = teamname
    session[:action] = :create
    redirect "/individualsalaries/#{id}"
  end

  get '/individualsalaries/:id' do


    if session[:action] == :create
      @results = session[:result]
      @teamname = session[:teamname]
      @playername = session[:playername1]
      @playername2 = session[:playername2]
    else
      request_url = "#{API_BASE_URI}/api/v1/check3/#{params[:id]}"
      options =  { headers: { 'Content-Type' => 'application/json' } }
      result = HTTParty.get(request_url, options)
      @results = result
    end

    @id = params[:id]
    @action = :update
    haml :individualsalaries
  end

  delete '/api/v1/check3/:id' do
    income = Income.destroy(params[:id])
  end

  post '/api/v1/check3' do
    content_type :json

    body = request.body.read
    logger.info body
    begin
      req = JSON.parse(body)
      logger.info req
    rescue Exception => e
      puts e.message
      halt 400
    end
    incomes = Income.new
    incomes.teamname = req['teamname']
    incomes.playername1 = req['playername1']
    incomes.playername2 = req['playername2']

    if incomes.save
      redirect "api/v1/check3/#{incomes.id}"
    end
  end

  get '/api/v1/check3/:id' do
    content_type :json
    logger.info "GET /api/v1/check3/#{params[:id]}"
    begin
      @income = Income.find(params[:id])

      teamname = [@income.teamname]
      puts teamname
      playernames = [@income.playername1,@income.playername2]


    rescue
      halt 400
    end

    result = two_players_salary_data2(teamname, playernames).to_json
    logger.info "result: #{result}\n"
    result
  end

  get '/playertotal' do
    @action2 = :create
    haml :playertotal
  end

  post '/playertotal' do
    request_url = "#{API_BASE_URI}/api/v1/incomes"


    teamname = params[:teamname]
    playername1 = params[:playername1]
    params_h = {
          teamname: teamname,
          playername1: playername1
    }

    options =  {
                  body: params_h.to_json,
                  headers: { 'Content-Type' => 'application/json' }
               }

    result = HTTParty.post(request_url, options)

    if (result.code != 200)
      flash[:notice] = 'Player not found! Ensure that team and player name is spelled correctly. '
      redirect '/playertotal'
      return nil
    end

    id = result.request.last_uri.path.split('/').last
    session[:result] = result.to_json
    session[:playername1] = playername1
    session[:teamname] = teamname
    session[:action] = :create
    redirect "/playertotal/#{id}"
  end

  get '/playertotal/:id' do
    if session[:action] == :create
      @fullpay = session[:result]
      @teamname2 = session[:teamname]
      @playername2 = session[:playername1]
    else
      request_url = "#{API_BASE_URI}/api/v1/incomes/#{params[:id]}"
      options =  { headers: { 'Content-Type' => 'application/json' } }
      result = HTTParty.get(request_url, options)
      @fullpay = JSON.parse(result)

    end

    @id = params[:id]
    @action2 = :update

    haml :playertotal
  end

  delete '/api/v1/incomes/:id' do
    income = Income.destroy(params[:id])
  end

  get '/api/v1/incomes/:id' do
    content_type :json
    logger.info "GET /api/v1/incomes/#{params[:id]}"
    begin
      @total = Income.find(params[:id])
      teamname = [@total.teamname]
      puts teamname
      playername1 = [@total.playername1]
      puts playername1

    rescue
      halt 400
    end

    result = player_total_salary2(teamname, playername1).to_json
    logger.info "result: #{result}\n"
    result
  end

  post '/api/v1/incomes' do
    content_type :json

    body = request.body.read
    logger.info body
    begin
      req = JSON.parse(body)
      logger.info req
    rescue Exception => e
      puts e.message
      halt 400
    end
    incomes = Income.new
    incomes.teamname = req['teamname']
    incomes.playername1 = req['playername1']

    if incomes.save
      redirect "api/v1/incomes/#{incomes.id}"
    end
  end

  get '/api/v1/:teamname.json' do
      content_type :json
      get_team2(params[:teamname]).to_json

  end

  get '/api/v1/players/:teamname.json' do
    content_type :json
    get_team_players(params[:teamname]).to_json
  end

  post '/api/v1/check' do
    content_type :json
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end
    teamname = req['teamname']
    player_name = req['player_name']
    player_salary_data(teamname, player_name).to_json
  end

  post '/api/v1/check2' do
    content_type :json
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end
    teamname = req['teamname']
    player_name = req['player_name']
    player_total_salary2(teamname, player_name).to_json
  end



  not_found do
    status 404
    'not found'
  end
end
