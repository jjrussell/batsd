# Gets the list of offers from offerpal

class Job::CreateRewardedInstallsController < Job::SqsReaderController
  include DownloadContent
  include MemcachedHelper
  
  def initialize
    super QueueNames::CREATE_REWARDED_INSTALLS
  end
  
  private 
  
  def on_message(message)
    
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
    
    #first get the list of all apps paying for installs
    app_list = []
    App.select(:where => 
        "payment_for_install > '0' " +
        " and install_tracking = '1'" +
        " and rewarded_installs_ordinal != ''" +
        " and balance > '0'") do |app|
      app_list.push(app)
    end
    
    # Sort all apps based on cvr.
    app_list.sort! do |app1, app2|
      get_cvr_for_ranking(app2) - get_cvr_for_ranking(app1)
    end
    
    # Re-order apps which have an ordinal set.
    apps_to_swap = []
    app_list.each do |app|
      if app.get('rewarded_installs_ordinal').to_i < 100
        apps_to_swap.push(app)
      end
    end
    apps_to_swap.each do |app|
      app_list.delete(app)
      app_list.insert(app.get('rewarded_installs_ordinal').to_i - 1, app)
    end
    
    serialized_app_list = []
    app_list.each do |app|
      serialized_app_list.push(app.serialize)
    end
    
    
    bucket.put('rewarded_installs_list', serialized_app_list.to_json)
    save_to_cache('s3.offer-data.rewarded_installs_list', serialized_app_list.to_json)
  end
  
  def get_cvr_for_ranking(app)
    boost = 0
    if app.key == '875d39dd-8227-49a2-8af4-cbd5cb583f0e'
      # MyTown: boost cvr by 20-30%
      boost = 0.2 + rand * 0.1
    elsif app.key == 'f8751513-67f1-4273-8e4e-73b1e685e83d'
      # Movies: boost cvr by 35-40%
      boost = 0.35 + rand * 0.05
    elsif app.key == '547f141c-fdf7-4953-9895-83f2545a48b4'
      # CauseWorld: US-only, so it has a low cvr. Boost it by 30-40%
      boost = 0.3 + rand * 0.1
    elsif app.get('partner_id') == '70f54c6d-f078-426c-8113-d6e43ac06c6d' and app.is_free
      # Tapjoy apps: reduce cvr by 5%
      boost = -0.05
    elsif not app.is_free
      # Boost all paid apps by 0-15%, causing churn.
      boost = rand * 0.15
    end
    
    app.get('pay_per_click') == '1' ? 0.75 + rand * 0.15 : app.get('conversion_rate').to_f + boost
  end
end