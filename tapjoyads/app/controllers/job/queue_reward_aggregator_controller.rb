class Job::QueueRewardAggregatorController < Job::SqsReaderController
  include DownloadContent
  include TimeLogHelper
  
  def initialize
    super QueueNames::REWARD_AGGREGATOR
  end
  
  def aggregate_day
    time = Time.now.utc
    24.times do |hour|
      min_time = Time.utc(time.year, time.month, time.day, hour)
      max_time = min_time + 1.hour
    
      msg = { 'start_hour' => min_time.to_f.to_s, 'last_hour' => max_time.to_f.to_s }.to_json
      on_message(msg)
    end
    render :text => 'ok'
  end
  
  private
  
  ##
  # params: start_hour, last_hour
  
  def on_message(message)
    
    time_log('Aggregating reward stats') do
      json = JSON.parse(message.to_s)
    
      #start_hour is an epoch
      start_hour = json['start_hour'].to_f    
      last_hour = json['last_hour'].to_f
    
      publishers = {}
      advertisers = {}
        
      Reward.select(:where => "created >= '#{start_hour}' and created < '#{last_hour}'") do |reward|
        
        publishers[reward.get('publisher_app_id')] = { :offers => 0, :ratings => 0, 
          :offers_revenue => 0, :installs_revenue => 0, 
          :total_rewards => 0, :total_revenue => 0 } unless publishers[reward.get('publisher_app_id')]
        advertisers[reward.get('advertiser_app_id')] = { 
          :cost => 0 } unless advertisers[reward.get('advertiser_app_id')]

        case reward.get('type')
        when 'install'
          publishers[reward.get('publisher_app_id')][:installs_revenue] += reward.get('publisher_amount').to_i
          advertisers[reward.get('advertiser_app_id')][:cost] += reward.get('advertiser_amount').to_i
        when 'offer'
          publishers[reward.get('publisher_app_id')][:offers] += 1
          publishers[reward.get('publisher_app_id')][:offers_revenue] += reward.get('publisher_amount').to_i        
        when 'rating'
          publishers[reward.get('publisher_app_id')][:ratings] += 1
        end
    
        publishers[reward.get('publisher_app_id')][:total_rewards] += 1
        publishers[reward.get('publisher_app_id')][:total_revenue] += reward.get('publisher_amount').to_i
      end
        
      #now that all the data is in publishers, advertisers, set the stats
      hour = Time.at(start_hour).utc.hour
      publishers.each do |key, publisher|
        offers_opened = OfferClick.count(
            :where => "app_id = '#{key}' and click_date >= '#{start_hour}' and click_date < '#{last_hour}'")
      
        stat = Stats.new(:key => get_stat_key('app', key, start_hour))
      
        update_stat(stat, 'installs_revenue', publisher[:installs_revenue], hour)
        update_stat(stat, 'offers', publisher[:offers], hour)
        update_stat(stat, 'offers_revenue', publisher[:offers_revenue], hour)
        update_stat(stat, 'offers_opened', offers_opened, hour)
        update_stat(stat, 'ratings', publisher[:ratings], hour)
        update_stat(stat, 'rewards', publisher[:total_rewards], hour)
        update_stat(stat, 'rewards_revenue', publisher[:total_revenue], hour)
        update_stat(stat, 'rewards_opened', offers_opened + installs_opened, hour)
      
        Rails.logger.info("Publisher #{key}: #{publisher}")
        stat.save          
      end
    
      advertisers.each do |key, advertiser|
        stat = Stats.new(:key => get_stat_key('app', key, start_hour))
        update_stat(stat, 'installs_spend', advertiser[:cost], hour)
      
        Rails.logger.info("Advertiser #{key}: #{advertiser}")
        stat.save
      end
    end #time log
  end
  
  def update_stat(stat, field, value, hour)
    val_string = stat.get(field)
    if val_string
      vals = val_string.split(',')
    else
      vals = Array.new(24,0)
    end
    
    vals[hour] = value
    
    stat.put(field, vals.join(','))
  end
  
  def get_stat_key(item_type, item_id, time)
    date = Time.at(time).utc.iso8601[0,10]
    return "#{item_type}.#{date}.#{item_id}"
  end
  
end
