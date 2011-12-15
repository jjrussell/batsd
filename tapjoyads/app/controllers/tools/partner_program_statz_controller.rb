class Tools::PartnerProgramStatzController < WebsiteController
  include ActionView::Helpers::NumberHelper

  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :setup, :only => [ :index, :export ]

  def index
    @partner_program_metadata, @partner_program_stats, @partner_revenue_stats, @partner_names = get_stats(@start_time, @end_time)
  end

  def export
    data = generate_csv()
    send_data(data.join("\n"), :type => 'text/csv', :filename => "Tapjoy_sponsored_publishers_stats_#{@start_time.to_s(:yyyy_mm_dd)}_#{@end_time.to_s(:yyyy_mm_dd)}.csv")
  end

private

  def setup
    @start_time, @end_time, @granularity = Appstats.parse_dates(params[:date], params[:end_date], params[:granularity])
  end

  def get_stats(start_time, end_time)
    return {},{},{},{} if Offer.tapjoy_sponsored_offer_ids.size == 0
    time_conditions      = "time >= '#{start_time.to_s(:db)}' AND time < '#{end_time.to_s(:db)}'"
    partner_program_offer_ids = Offer.tapjoy_sponsored_offer_ids.map { |o| "'#{o.id}'" }.join(',')  #is it necessary to add Offer.enabled_offers.tapjoy_sponsored_offer_ids here?

    partner_program_stats = {}
    VerticaCluster.query('analytics.actions', {
        :select     => 'offer_id, count(*) AS conversions',
        :group      => 'offer_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions} AND offer_id IN (#{partner_program_offer_ids})" }).each do |result|
      partner_program_stats[result[:offer_id]] = {
        'conversions'      => number_with_delimiter(result[:conversions]),
        'published_offers' => '0',
        'offers_revenue'   => 0,
      }
    end
    VerticaCluster.query('analytics.actions', {
        :select     => 'publisher_app_id AS offer_id, count(*) AS published_offers, sum(publisher_amount) AS offers_revenue',
        :group      => 'publisher_app_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions} AND publisher_app_id IN (#{partner_program_offer_ids})" }).each do |result|
      partner_program_stats[result[:offer_id]] ||= { 'conversions' => '0' }
      partner_program_stats[result[:offer_id]]['published_offers'] = number_with_delimiter(result[:published_offers])
      partner_program_stats[result[:offer_id]]['offers_revenue']   = result[:offers_revenue]
    end

    partner_revenue_stats = {}
    partner_names = {}
    partner_program_metadata = {}
    Offer.find_each(:conditions => [ 'id IN (?)', partner_program_stats.keys ], :include => :partner) do |offer|
      partner_program_metadata[offer.id] = {
        'icon_url'           => offer.get_icon_url,
        'offer_name'         => offer.name_with_suffix,
        'price'              => number_to_currency(offer.price / 100.0),
        'payment'            => number_to_currency(offer.payment / 100.0),
        'balance'            => number_to_currency(offer.partner.balance / 100.0),
        'conversion_rate'    => number_to_percentage((offer.conversion_rate || 0) * 100.0, :precision => 1),
        'platform'           => offer.get_platform,
        'featured'           => offer.featured?,
        'rewarded'           => offer.rewarded?,
        'offer_type'         => offer.item_type,
        'overall_store_rank' => combined_ranks[offer.third_party_data] || '-',
        'sales_rep'          => offer.partner.sales_rep.to_s,
        'partner_pending_earnings'  => offer.partner.pending_earnings,
        'partner_id'         => offer.partner.id
      }
      partner_names[offer.partner.id] ||= offer.partner.name
      partner_revenue_stats[offer.partner.id] ||= 0
      partner_revenue_stats[offer.partner.id] += partner_program_stats[offer.id]['offers_revenue']
    end

    partner_program_stats_adv = partner_program_stats.sort do |s1, s2|
      s2[1]['conversions'].gsub(',', '').to_i <=> s1[1]['conversions'].gsub(',', '').to_i
    end

    return partner_program_metadata, partner_program_stats_adv, partner_revenue_stats, partner_names
  end

  def combined_ranks
    @combined_ranks ||= begin
      ios_ranks_free     = Mc.get('store_ranks.ios.overall.free.united_states') || {}
      ios_ranks_paid     = Mc.get('store_ranks.ios.overall.paid.united_states') || {}
      android_ranks_free = Mc.get('store_ranks.android.overall.free.english')   || {}
      android_ranks_paid = Mc.get('store_ranks.android.overall.paid.english')   || {}

      ios_ranks_free.merge(ios_ranks_paid).merge(android_ranks_free).merge(android_ranks_paid)
    end
  end

  def generate_csv
    data = ["Offer,Publisher_name,Conversions,Store_rank,Price,Payment,Balance,Platform,CVR,Published_offers,Offers_revenue,Publisher_Revenue,Publisher_pending_earnings,Featured,Rewarded,Offer_type,Sales_rep"]
    @partner_program_metadata, @partner_program_stats, @partner_revenue_stats, @partner_names = get_stats(@start_time, @end_time)
    @partner_program_stats.each do |offer_id, stats|
      metadata = @partner_program_metadata[offer_id]
      line = [
        metadata['offer_name'].gsub(/[,]/,' '),
        @partner_names[metadata['partner_id']],
        stats['conversions'].gsub(/[,]/,''),
        metadata['overall_store_rank'].gsub(/[,]/,''),
        metadata['price'].gsub(/[,]/,''),
        metadata['payment'].gsub(/[,]/,''),
        metadata['balance'].gsub(/[,]/,''),
        metadata['platform'],
        metadata['conversion_rate'],
        stats['published_offers'].gsub(/[,]/,''),
        number_to_currency(stats['offers_revenue'] / 100.0, :delimiter => ''),
        number_to_currency(@partner_revenue_stats[metadata['partner_id']] / 100.0, :delimiter => ''),
        number_to_currency(metadata['partner_pending_earnings'] / 100.0, :delimiter => ''),
        metadata['featured'],
        metadata['rewarded'],
        metadata['offer_type'],
        metadata['sales_rep']
      ]
      data << line.join(',')
    end
    data
  end

end
