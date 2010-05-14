class Job::QueueSelectVgItemsController < Job::SqsReaderController
  include MemcachedHelper
  
  def initialize
    super QueueNames::SELECT_VG_ITEMS
  end
  
  private
  
  def on_message(message)
    app_set = Set.new
    
    VirtualGood.select(:attributes => 'app_id') do |vg|
      unless app_set.include?(vg.app_id)
        cache_for_app_key(vg.app_id)
        app_set.add(vg.app_id)
      end
    end
  end
  
  def cache_for_app_key(app_key)
    mc_key = "virtual_good_list.#{app_key}"
    list = []
    VirtualGood.select(:where => "app_id='#{app_key}' and disabled != '1' and beta != '1'") do |item|
      list.push(item)
    end
    save_to_cache(mc_key, list, false, 10.minutes)
    
    mc_key = "virtual_good_list.beta.#{app_key}"
    list = []
    VirtualGood.select(:where => "app_id='#{app_key}' and disabled != '1' and beta = '1'") do |item|
      list.push(item)
    end
    save_to_cache(mc_key, list, false, 10.minutes)
  end
end
