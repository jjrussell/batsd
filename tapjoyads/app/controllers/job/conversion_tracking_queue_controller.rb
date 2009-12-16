class Job::ConversionTrackingQueueController < Job::SqsReaderController
  include DownloadContent
  include RewardHelper
  
  def initialize
    super QueueNames::CONVERSION_TRACKING
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    udid = json['udid']
    advertiser_app_id = json['app_id']
    install_date = json['install_date']
    
    Rails.logger.info "Checking for conversion on #{udid} for #{advertiser_app_id}"
    click = StoreClick.new("#{udid}.#{advertiser_app_id}")

    if (click.get('click_date') && (not click.get('installed')) ) #there has been a click but no install
      
      adv_app = App.new(advertiser_app_id)
      
      publisher_app_id = click.get('publisher_app_id')
      currency = Currency.new(publisher_app_id)
      
      values = calculate_install_payouts(:currency => currency, :advertiser_app => adv_app)
      
      user = SimpledbResource.select('publisher-user-record','*', "record_id = '#{click.get('publisher_user_record_id')}'")
      if user.items.length == 0
        click.put('publisher_user_record_id_not_found',click.get('publisher_user_record_id'))
        click.save #save this item so we can look it up later
        raise("Install record_id not found: #{record_id} with store click id: #{click.key}")
      end
      
      unless click.get('currency_reward')
        values = calculate_install_payouts(:currency => currency, :advertiser_app => adv_app)

        click.put('advertiser_amount', values[:advertiser_amount])
        click.put('publisher_amount', values[:publisher_amount])
        click.put('currency_reward', values[:currency_reward])
        click.put('tapjoy_amount', values[:tapjoy_amount])
        click.put('offerpal_amount', values[:offerpal_amount])
        
      end
      
      record = user.items.first
      publisher_user_id = record.key.split('.')[1]
      
      reward = Reward.new
      reward.put('type', 'install')
      reward.put('publisher_app_id', publisher_app_id)
      reward.put('advertiser_app_id', advertiser_app_id)
      reward.put('publisher_user_id', publisher_user_id)
      reward.put('advertiser_amount', click.get('advertiser_amount'))
      reward.put('publisher_amount', click.get('publisher_amount'))
      reward.put('currency_reward', click.get('currency_reward'))
      reward.put('tapjoy_amount', click.get('tapjoy_amount'))
      reward.put('offerpal_amount', click.get('offerpal_amount'))
      
      reward.save
      
      message = reward.serialize()
      
      SqsGen2.new.queue(QueueNames::SEND_CURRENCY).send_message(message)
      SqsGen2.new.queue(QueueNames::SEND_MONEY_TXN).send_message(message)
      
      click.put('installed', "#{install_date.to_s}")
      click.save
    end
  end
end