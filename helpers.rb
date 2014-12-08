require 'nbasalaryscrape'

  module Helpers

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
