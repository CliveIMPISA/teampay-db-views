require 'sinatra/base'
require 'sinatra'
require 'nbasalaryscrape'
require 'json'
require_relative 'model/income'
require 'haml'
require 'sinatra/flash'

# nbasalaryscrape service
class TeamPayApp < Sinatra::Base
  enable :sessions
  register Sinatra::Flash

  configure :production, :development do
    enable :logging
  end

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
      team = get_team(teamname)
      team_players = []
      team.each do |player_salary_scrape|
        team_players << player_salary_scrape['Player']
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
      salary_scrape = get_team(teamname[0])
      player_name.each do |each_player|
        salary_scrape.each do |data_row|
          if data_row['Player'] == each_player
            players << one_total(data_row, each_player)
          end
        end
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
    haml :individualsalaries
  end

  post '/individualsalaries' do
    income = Income.new
    income.player_names2 = params[:playername2]
    income.teamnames = params[:teamname]
    income.player_names = params[:playername1]

    if params[:playername2]=="" || params[:playername1]==""
      flash[:notice] = 'Error! Incorrect Inputs'
      redirect '/individualsalaries'
    end

    if income.save
      redirect "/individualsalaries/#{income.id}"
    end

    haml :individualsalaries
  end

  get '/individualsalaries/:id' do

      income = Income.find(params[:id])
      teamname = [income.teamnames]
      player_names = [income.player_names,income.player_names2]
      @Results = two_players_salary_data(teamname, player_names)
    if @Results.nil?
      flash[:notice] = 'Players Not Found! Check Spelling and Team selected' if @Results.nil?
      redirect '/individualsalaries'
    end


    haml :individualsalaries
  end

  get '/api/v1/incomes/:id' do
    content_type :json
    begin
      income = Income.find(params[:id])
      teamname = JSON.parse(income.teamnames)
      player_names = JSON.parse(income.player_names)
    rescue
      halt 400
    end
    player_total_salary(teamname, player_names).to_json
  end

  post '/api/v1/incomes' do
      content_type :json
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end
    income = Income.new
    income.description = req['description'].to_json
    income.teamnames = req['teamname'].to_json
    income.player_names = req['player_name'].to_json

    if income.save
      status 201
      redirect "/api/v1/incomes/#{income.id}"
    end
  end

  get '/api/v1/:teamname.json' do
      content_type :json
      get_team(params[:teamname]).to_json
  end

  get '/api/v1/form' do
    erb :form
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
    player_total_salary(teamname, player_name).to_json
  end

  post '/api/v1/check3' do
    content_type :json
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end
    teamname = req['teamname']
    player_name = req['player_name']
    two_players_salary_data(teamname, player_name).to_json
  end

  get '/api/v1/players/:teamname.json' do
    content_type :json
    get_team_players(params[:teamname]).to_json
  end

  post '/form' do
    content_type :json
    get_team(params[:message]).to_json
  end

  not_found do
    status 404
    'not found'
  end
end
