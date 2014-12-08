require 'sinatra/base'
require 'sinatra'
require 'json'
#require 'nbasalaryscrape'
require_relative 'model/income'
require_relative 'helpers'
require 'haml'
require 'sinatra/flash'
require 'httparty'

# nbasalaryscrape service
class TeamPayApp < Sinatra::Base
  enable :sessions
  register Sinatra::Flash

  configure :production, :development do
    enable :logging
  end

  helpers do
    include Helpers
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

  get '/playertotal' do
    haml :playertotal
  end

  post '/playertotal' do
    income = Income.new
    income.teamnames = params[:teamname]
    income.player_names = params[:playername1]

    if params[:playername1]==""
      flash[:notice] = 'Error! Incorrect Inputs'
      redirect '/playertotal'
    end

    if income.save
      redirect "/playertotal/#{income.id}"
    end

    haml :playertotal
  end

  get '/playertotal/:id' do

      income = Income.find(params[:id])
      teamname = [income.teamnames]
      player_names = [income.player_names]
      @Result = player_total_salary(teamname, player_names)
    if @Result.nil?
      flash[:notice] = 'Players Not Found! Check Spelling and Team selected' if @Result.nil?
      redirect '/playertotal'
    else
      @player=@Result[0][0]['player']
      @fullpay=@Result[0][0]['fullpay']
    end


    haml :playertotal
  end

  get '/playertotal/edit/:id' do
    session[:action] = :edit
    @id = params[:id]
    income = Income.find(@id)
    @teamname = income.teamnames
    @player = income.player_names

    haml :playertotal
  end

  not_found do
    status 404
    'not found'
  end


  #API starts here

  get '/api/v2/incomes/:id' do
    content_type :json
    begin
      income = Income.find(params[:id])
      teamname = JSON.parse(income.teamnames)
      player_names = JSON.parse(income.player_names)
    rescue
      halt 400
    end
    player_total_salary2(teamname, player_names).to_json
  end

  post '/api/v2/incomes' do
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
      redirect "/api/v2/incomes/#{income.id}"
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



end
