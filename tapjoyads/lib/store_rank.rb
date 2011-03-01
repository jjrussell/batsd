class StoreRank
  cattr_accessor :itunes_category_ids, :itunes_pop_ids, :itunes_country_ids
  
  def self.populate_store_rankings(time)
    hydra = Typhoeus::Hydra.new(:max_concurrency => 20)
    hydra.disable_memoization
    date_string = time.to_date.to_s(:db)
    error_count = 0
    success_count = 0
    known_store_ids = {}
    stat_rows = {}
    
    ranks_file_name = "ranks.#{time.beginning_of_hour.to_s(:db)}.json"
    ranks_file = open("tmp/#{ranks_file_name}", 'w')
    
    log_progress "Populate store rankings. Task starting."
    
    App.find_each(:conditions => "platform = 'iphone' AND store_id IS NOT NULL") do |app|
      known_store_ids[app.store_id] ||= []
      known_store_ids[app.store_id] += app.offer_ids
    end
    log_progress "Finished loading known_store_ids."
    
    itunes_category_ids.each do |category_key, category_id|
      itunes_pop_ids.each do |pop_key, pop_id|
        itunes_country_ids.each do |country_key, country_id|
          stat_type = "#{category_key}.#{pop_key}.#{country_key}"
          url = "http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?id=#{category_id}&popId=#{pop_id}"
          headers = { 'X-Apple-Store-Front' => "#{country_id}-1,12", 'Host' => 'ax.itunes.apple.com' }
          user_agent = 'iTunes/10.1 (Macintosh; Intel Mac OS X 10.6.5) AppleWebKit/533.18.1'
          
          request = Typhoeus::Request.new(url, :headers => headers, :user_agent => user_agent)
          request.on_complete do |response|
            if response.code != 200
              error_count += 1
              if error_count > 50
                raise "Too many errors attempting to download itunes ranks, giving up. App store down?"
              end
              log_progress "Error downloading ranks from itunes for category: #{category_key}, pop: #{pop_key}, country: #{country_key}. Error code: #{response.code}. Retrying."
              hydra.queue(request)
            else
              success_count += 1
              ranks_hash = get_itunes_ranks_hash(response.body)
              ranks_hash.each do |store_id, rank|
                next if known_store_ids[store_id].nil?

                known_store_ids[store_id].each do |offer_id|
                  stat_rows[offer_id] ||= Stats.new(:key => "app.#{date_string}.#{offer_id}", :load_from_memcache => false)
                  stat_rows[offer_id].update_stat_for_hour(['ranks', stat_type], time.hour, rank)
                  
                  # TO REMOVE - once this job consistently runs every hour.
                  if time.hour > 0 && stat_rows[offer_id].get_hourly_count(['ranks', stat_type])[time.hour - 1] == 0
                    stat_rows[offer_id].update_stat_for_hour(['ranks', stat_type], time.hour - 1, rank)
                  end
                end
              end

              ranks_file.puts( {"itunes.#{stat_type}" => ranks_hash}.to_json )
            end
          end
          hydra.queue(request)
        end
      end
    end
    log_progress "Finished queuing requests."
    
    hydra.run
    log_progress "Finished making requests."
    
    stat_rows.each do |offer_id, stat_row|
      stat_row.serial_save
    end
    log_progress "Finished saving stat_rows."
    
    ranks_file.close
    `gzip -f 'tmp/#{ranks_file_name}'`
    
    retries = 3
    begin
      bucket = S3.bucket(BucketNames::STORE_RANKS)
      bucket.put("#{ranks_file_name}.gz", open("tmp/#{ranks_file_name}.gz"))
    rescue RightAws::AwsError => e
      log_progress "Failed attempt to write to s3. Error: #{e}"
      if (retries -= 1) > 0
        sleep(1)
        log_progress "Retrying to write to s3."
        retry
      else
        raise e
      end
    end
    
    log_progress "Finished saving store_rankings."
  ensure
    `rm 'tmp/#{ranks_file_name}'`
    `rm 'tmp/#{ranks_file_name}.gz'`
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
  
  def self.log_progress(message)
    now = Time.zone.now
    Rails.logger.info "#{now} (#{now.to_i}): #{message}"
    Rails.logger.flush
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
    "games_casino"            => 26391,
    "games_dice"              => 26401,
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
  
  @@itunes_pop_ids      = {
    "free"              => 27,
    "paid"              => 30,
    "top_grossing"      => 38,
    "ipad_free"         => 44,
    "ipad_paid"         => 47,
    "ipad_top_grossing" => 46,
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
