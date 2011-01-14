class Job::MasterAppRanksController < Job::JobController
  def initialize
    @now = Time.zone.now
  end
  
  def index
    date_string = @now.to_date.to_s(:db)

    StoreRank.populate_store_rankings(@now)
    
    tp = ThreadPool.new(25)
    
    Offer.find_each do |offer|
      next unless offer.item_type == 'App' && offer.get_platform == 'iOS'
      
      tp.process do
        stat_row = Stats.new(:key => "app.#{date_string}.#{offer.id}")
        StoreRanks.populate_ranks(offer.third_party_data, stat_row, @now)
        stat_row.serial_save
      end
    end
    
    tp.join
    
    render :text => 'ok'
  end
end