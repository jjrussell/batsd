class Job::CacheReengagementOffersController < Job::JobController

  def index
    puts 'About to cache reengagement offers'
    app_ids_with_reengagement_offers = ReengagementOfferj.visible.find(:all, :select => 'DISTINCT app_id')
    app_ids_with_reengagement_offers.each do |a|
      puts "App id with ro: #{a}"
    end
  end
end
