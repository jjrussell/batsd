class StoreRank
  cattr_accessor :itunes_category_ids, :itunes_pop_ids, :itunes_country_ids
  
  ##
  # Populates the 'overall_store_rank' stat, which is the app's location in the US free app chart.
  def self.populate_overall_store_rank(store_id, stat_row, hour)
    if stat_row.get_hourly_count('overall_store_rank', 0)[hour].to_i == 0
      rank_hash = get_ranks_hash(itunes_category_ids['overall'], itunes_pop_ids['free'], itunes_country_ids['united_states'])
      rank = rank_hash[store_id] || '-'
      stat_row.update_stat_for_hour('overall_store_rank', hour, rank)
    end
  end
  
  def self.get_ranks_hash(category_id, pop_id, country_id)
    url = "http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?id=#{category_id}&popId=#{pop_id}"
    headers = {
      'User-Agent' => 'iTunes/10.1 (Macintosh; Intel Mac OS X 10.6.5) AppleWebKit/533.18.1',
      'X-Apple-Store-Front' => "#{country_id}-1,12"
    }
    
    Mc.get_and_put("rankings.itunes.#{category_id}.#{pop_id}.#{country_id}", false, 1.hour) do 
      response = Downloader.get(url, :headers => headers, :timeout => 30)
      list = response.scan(/adam-id="(\d*)"/m).uniq.flatten
      hash = {}
      list.each_with_index do |id, index|
        hash[id] = index + 1
      end
      hash
    end
  end
  
  def self.populate_ranks(store_id, stat_row, hour)
    # TODO: populate every combination of ranks
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