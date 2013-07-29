module NFLScraper
  require 'net/http'
  require 'nokogiri'
  require 'open-uri'
  require 'csv'

  class Scraper
    def initialize
      @num_odd_players = []
      @num_even_players = []
      @num_sub_links = []
      @number_of_strings = ""
      @sliced_array = []
      @last_names = []
      @first_names = []
      @teams = []
      @players = []
      @array = []
    end

    def parse_master
      print "\e[2J\e[f"
      alphabet = ("A".."Z").to_a

      alphabet.each do |letter|
        nokogiri(letter)
        prepare_for_creation
        create_last_names
        create_first_names
        create_teams
        create_player
        reset_variables
      end
    end

    def reset_variables
      @num_odd_players = []
      @num_even_players = []
      @num_sub_links = []
      @number_of_strings = ""
      @sliced_array = []
      @last_names = []
      @first_names = []
      @teams = []
      @players = []
      @array = []
    end

    def nokogiri(letter)
      @letter = letter
      page = Nokogiri::HTML(open("http://www.nfl.com/players/search?category=lastName&playerType=current&d-447263-p=1&filter=#{letter}"))

      if !page.search('#searchResults').inner_text =~ /No players found/
        @num_sub_links = page.search('span').inner_text[-9].to_i
        @num_sub_links = 1 if @num_sub_links <= 1
        p
        puts "----------------------------------------------------------------------------"
        puts "I am currently scraping the players with last name starting with #{letter}."
        puts "There are #{@num_sub_links} sub pages for this letter"

        1.upto(@num_sub_links) do |num|
          puts "----------------------------------------------------------------------------"
          puts "I am in sub page #{num} of #{@num_sub_links} right now"
          page = Nokogiri::HTML(open("http://www.nfl.com/players/search?category=lastName&playerType=current&d-447263-p=#{num}&filter=#{letter}"))

          # Something specific for each page. Should be included in every letter
          @num_odd_players = page.search('tr.odd').count
          @adj_num_odd_players = @num_odd_players *2
          # p @adj_num_odd_players

          @num_even_players = page.search('tr.even').count
          @adj_num_even_players = @num_even_players *2
          # p @adj_num_even_players

          total = @adj_num_odd_players + @adj_num_even_players
          puts "There are #{total} players in that subpage"

          #gets the string for all odd players including first and last names and team
          @adj_num_odd_players.times do |x|
            @array << page.css('tr.odd a')[x].text
          end

          #PRODUCTIONS
          #gets the webpage for all odd players including first and last names and team
          @adj_num_odd_players.times do |x|
            @array << page.css('tr.odd a')[x]['href']
          end

          #gets the string for all even players including first and last names and team
          @adj_num_even_players.times do |x|
            @array << page.css('tr.even a')[x].text
          end
        end
      end
    end

    def prepare_for_creation
      @number_of_strings = @array.size/2
      @number_of_strings.times do
        @sliced_array << @array.slice!(0..1)
      end
    end

    def create_last_names
      @number_of_strings.times do |x|
        @last_names << @sliced_array[x][0].split(", ")[0]
      end
    end

    def create_first_names
      @number_of_strings.times do |x|
        @first_names << @sliced_array[x][0].split(", ")[1]
      end
    end

    def create_teams
      @number_of_strings.times do |x|
        @teams << @sliced_array[x][1]
      end
    end

    def create_player
      @teams.size.times do |x|
        first = @first_names[x]
        last = @last_names[x]
        team = @teams[x]
        @players << Player.new(last, first, team)
        current_player = [last, first, team]
        puts "creating player: #{last}, #{first} of team: #{team}"
      end
      save_players
      puts "------------------------------------------------------------"
      puts "There are a total of #{@players.size} in your chosen range."
    end

    def save_players
      play_ar = []
      @players.each do |player|
        play_ar << [player.last_name, player.first_name, player.team]
      end

      CSV.open("nfl_scraper_letter_#{@letter}.csv", "w") do |csv|
        play_ar.each do |player|
          csv << player.to_a
        end
      end
    end
  end

  class Player
    attr_reader :last_name, :first_name, :team

    def initialize(last_name, first_name, team)
      @last_name = last_name
      @first_name = first_name
      @team = team
    end
  end
end


if $0 = __FILE__
  scraper = NFLScraper::Scraper.new
  scraper.parse_master
end
