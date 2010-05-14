class Job::QueueSelectVgItemsController < Job::SqsReaderController
  include MemcachedHelper
  
  def initialize
    super QueueNames::SELECT_VG_ITEMS
  end
  
  private
  
  def on_message(message)
    App.select(:attributes => 'itemName()') do |app|
      mc_key = "virtual_good_list.#{@app.key}"
      list = []
      VirtualGood.select(:where => "app_id='#{@app.key}' and disabled != '1' and beta != '1'") do |item|
        list.push(item)
      end
      save_to_cache(mc_key, list, false, 10.minutes)
      
      mc_key = "virtual_good_list.beta.#{@app.key}"
      list = []
      VirtualGood.select(:where => "app_id='#{@app.key}' and disabled != '1' and beta = '1'") do |item|
        list.push(item)
      end
      save_to_cache(mc_key, list, false, 10.minutes)
      list
    end
  end
end
