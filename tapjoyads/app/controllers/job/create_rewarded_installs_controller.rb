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
    serialized_app_list = []
    App.select(
        :where => "payment_for_install > '0' and install_tracking = '1' and rewarded_installs_ordinal != '' and balance > '0'",
        :order_by => "rewarded_installs_ordinal") do |item|
      app_list.push(item)
      serialized_app_list.push(item.serialize)
    end
    
    bucket.put('rewarded_installs_list', serialized_app_list.to_json)
    save_to_cache('s3.offer-data.rewarded_installs_list', serialized_app_list.to_json)
  end
end