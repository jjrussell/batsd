class StoreRank
  cattr_accessor :itunes_category_ids, :itunes_pop_ids, :itunes_country_ids, :cached_store_rankings
  
  @@cached_store_rankings = {}
  
  ##
  # Populates the 'overall_store_rank' stat, which is the app's location in the US free app chart.
  def self.populate_overall_store_rank(store_id, stat_row, hour)
    if stat_row.get_hourly_count(['ranks', 'overall.free.united_states'])[hour] == 0
      rank_hash = get_ranks_hash(itunes_category_ids['overall'], itunes_pop_ids['free'], itunes_country_ids['united_states'])
      rank = rank_hash[store_id]
      stat_row.update_stat_for_hour(['ranks', 'overall.free.united_states'], hour, rank)
    end
  end
  
  def self.populate_store_rankings(time)
    hydra = Typhoeus::Hydra.new
    hydra.disable_memoization
    
    error_count = 0
    
    store_rankings = []
    
    itunes_category_ids.each do |category_key, category_id|
      itunes_pop_ids.each do |pop_key, pop_id|
        itunes_country_ids.each do |country_key, country_id|
          store_ranking_key = "itunes.#{category_key}.#{pop_key}.#{country_key}.#{time.beginning_of_hour.to_s(:db)}"
          store_ranking = StoreRanking.new(:key => store_ranking_key)
          if store_ranking.ranks.blank?
            url = "http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?id=#{category_id}&popId=#{pop_id}"
            headers = { 'X-Apple-Store-Front' => "#{country_id}-1,12" }
            user_agent = 'iTunes/10.1 (Macintosh; Intel Mac OS X 10.6.5) AppleWebKit/533.18.1'
            
            request = Typhoeus::Request.new(url, :headers => headers, :user_agent => user_agent)
            request.on_complete do |response|
              if response.code != 200
                error_count += 1
                if error_count > 50
                  raise "Too many errors attempting to download itunes ranks, giving up. App store down?"
                end
                Rails.logger.info "Error downloading ranks from itunes for category: #{category_key}, pop: #{pop_key}, country: #{country_key}. Retrying."
                hydra.queue(request)
              end
              
              store_ranking.ranks = get_itunes_ranks_hash(response.body)
              @@cached_store_rankings[store_ranking_key] = store_ranking
              store_rankings << store_ranking
            end
            
            hydra.queue(request)
          end
        end
      end
    end
    
    hydra.run
    
    while store_rankings.present?
      retries = 3
      begin
        StoreRanking.put_items(store_rankings.first(25))
      rescue Exception => e
        if (retries -= 1) >= 0
          sleep(1)
          retry
        else
          raise e
        end
      end
      store_rankings.shift(25)
    end
  end

  def self.populate_ranks(store_id, stat_row, time)
    hour = time.hour
    itunes_category_ids.each do |category_key, category_id|
      itunes_pop_ids.each do |pop_key, pop_id|
        itunes_country_ids.each do |country_key, country_id|
          stat_type = "#{category_key}.#{pop_key}.#{country_key}"
          if stat_row.get_hourly_count(['ranks', stat_type])[hour] == 0
            store_ranking_key = "itunes.#{category_key}.#{pop_key}.#{country_key}.#{time.beginning_of_hour.to_s(:db)}"
            @@cached_store_rankings[store_ranking_key] ||= StoreRanking.new(:key => store_ranking_key)
            rank = @@cached_store_rankings[store_ranking_key].ranks[store_id]
            stat_row.update_stat_for_hour(['ranks', stat_type], hour, rank) if rank
          end
        end
      end
    end
  end
  
private

  ##
  # Parses an itunes top 200 response, and returns a hash of store_id => rank.
  def self.get_itunes_ranks_hash(response_body)
    hash = {}
    list = response_body.scan(/adam-id="(\d*)"/m).uniq.flatten
    list.each_with_index do |id, index|
      hash[id] = index + 1
    end
    
    hash
  end
  
  @@itunes_category_ids = {
    "overall"                 => 25204,
    "books"                   => 25470,
    "business"                => 25148,
    "education"               => 25156,
    "entertainment"           => 25164,
    "finance"                 => 25172,
    "healthcare_and_fitness"  => 25188,
    "lifestyle"               => 25196,
    "medical"                 => 26321,
    "music"                   => 25212,
    "navigation"              => 25220,
    "news"                    => 25228,
    "photography"             => 25236,
    "productivity"            => 25244,
    "reference"               => 25252,
    "social_networking"       => 25260,
    "sports"                  => 25268,
    "travel"                  => 25276,
    "utilities"               => 25284,
    "weather"                 => 25292,
    "all_games"               => 25180,
    "games_action"            => 26341,
    "games_adventure"         => 26351,
    "games_arcade"            => 26361,
    "games_board"             => 26371,
    "games_card"              => 26381,
    "games_casino"            => 26341,
    "games_dice"              => 26341,
    "games_educational"       => 26411,
    "games_family"            => 26421,
    "games_kids"              => 26431,
    "games_music"             => 26441,
    "games_puzzle"            => 26451,
    "games_racing"            => 26461,
    "games_role_playing"      => 26471,
    "games_simulation"        => 26481,
    "games_sports"            => 26491,
    "games_strategy"          => 26501,
    "games_trivia"            => 26511,
    "games_word"              => 26521,
  }
  
  @@itunes_pop_ids = {
    "free" => 27,
    "paid" => 30,
    "top_grossing" => 38,
  }
  
  @@itunes_country_ids = {
    "united_states"         => 143441,
    "argentina"             => 143505,
    "australia"             => 143460,
    "belgium"               => 143446,
    "brazil"                => 143503,
    "canada"                => 143455,
    "chile"                 => 143483,
    "china"                 => 143465,
    "colombia"              => 143501,
    "costa_rica"            => 143495,
    "croatia"               => 143494,
    "czech_republic"        => 143489,
    "denmark"               => 143458,
    "deutschland"           => 143443,
    "el_salvador"           => 143506,
    "espana"                => 143454,
    "finland"               => 143447,
    "france"                => 143442,
    "greece"                => 143448,
    "guatemala"             => 143504,
    "hong_kong"             => 143463,
    "hungary"               => 143482,
    "india"                 => 143467,
    "indonesia"             => 143476,
    "ireland"               => 143449,
    "israel"                => 143491,
    "italia"                => 143450,
    "japan"                 => 143462,
    "korea"                 => 143466,
    "kuwait"                => 143493,
    "lebanon"               => 143497,
    "luxembourg"            => 143451,
    "malaysia"              => 143473,
    "mexico"                => 143468,
    "nederland"             => 143452,
    "new_zealand"           => 143461,
    "norway"                => 143457,
    "osterreich"            => 143445,
    "pakistan"              => 143477,
    "panama"                => 143485,
    "peru"                  => 143507,
    "phillipines"           => 143474,
    "poland"                => 143478,
    "portugal"              => 143453,
    "qatar"                 => 143498,
    "romania"               => 143487,
    "russia"                => 143469,
    "saudi_arabia"          => 143479,
    "suisse"                => 143459,
    "singapore"             => 143464,
    "slovakia"              => 143496,
    "slovenia"              => 143499,
    "south_africa"          => 143472,
    "sri_lanka"             => 143486,
    "sweden"                => 143456,
    "taiwan"                => 143470,
    "thailand"              => 143475,
    "turkey"                => 143480,
    "united_arab_emirates"  => 143481,
    "united_kingdom"        => 143444,
    "venezuela"             => 143502,
    "vietnam"               => 143471,
  }
end