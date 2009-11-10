class GetstatsController < ApplicationController
  
  missing_message = "missing required params"
  verify :params => [:date, :item_type, :item_id],
         :render => {:text => missing_message}
         
  def adimpressions
    
    item_type = params[:item_type]
    item_id = params[:item_id]
    date = params[:date]
    
    if item_type == 'app'
      app = App.new(item_id)
      if app.item.empty?
          next_run_time = (Time.now.utc).to_f.to_s
          app.put('next_run_time', next_run_time)     
          app.put('interval_update_time','60')
        app.save
      end
    elsif item_type == 'campaign'
      campaign = Campaign.new(item_id)
      if campaign.item.empty?
          next_run_time = (Time.now.utc).to_f.to_s
          campaign.put('next_run_time', next_run_time)     
          campaign.put('interval_update_time','60')
        campaign.save
      end
    else
      render :text => "unsupported item_type"
      return
    end
    
    key = "#{item_type}.#{date}.#{item_id}"
    
    stat = Stats.new(key)
    
    hourly_impressions = stat.get('hourly_impressions')
    if hourly_impressions
      data = hourly_impressions.split(',')
      count = 0
      data.each do |i|
        count += i.to_i
      end
      render :text => count.to_s
    else
      render :text => "0"
    end
    
    
  end
  
end
