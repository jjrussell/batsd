class Tools::PartnerProgramStatzController < WebsiteController

  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :setup, :only => [ :index, :export ]

  def index
    @partner_program_metadata, @partner_program_stats, @partner_revenue_stats, @partner_names, @appstats_data = get_stats(@start_time, @end_time)
  end

  def export
    data = generate_csv
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
        :select     => 'offer_id, count(path) AS conversions, -sum(advertiser_amount) AS spend',
        :group      => 'offer_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions} AND offer_id IN (#{partner_program_offer_ids})" }).each do |result|
      partner_program_stats[result[:offer_id]] = {
        'conversions'       => NumberHelper.number_with_delimiter(result[:conversions]),
        'spend'             => NumberHelper.number_to_currency(result[:spend] / 100.0),
        'published_offers'  => '0',
        'gross_revenue'     => 0,
        'publisher_revenue' => 0,
      }
    end
    VerticaCluster.query('analytics.actions', {
        :select     => 'publisher_app_id AS offer_id, count(path) AS published_offers, sum(publisher_amount + tapjoy_amount) AS gross_revenue, sum(publisher_amount) AS publisher_revenue',
        :group      => 'publisher_app_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions} AND publisher_app_id IN (#{partner_program_offer_ids})" }).each do |result|
      partner_program_stats[result[:offer_id]] ||= { 'conversions' => '0', 'spend' => '$0.00' }
      partner_program_stats[result[:offer_id]]['published_offers'] = NumberHelper.number_with_delimiter(result[:published_offers])
      partner_program_stats[result[:offer_id]]['gross_revenue']   = result[:gross_revenue]
      partner_program_stats[result[:offer_id]]['publisher_revenue']   = result[:publisher_revenue]
    end

    partner_revenue_stats = {}
    partner_names = {}
    partner_program_metadata = {}
    appstats_data = {}
    Offer.find_each(:conditions => [ 'id IN (?)', partner_program_stats.keys ], :include => :partner) do |offer|

      appstats = Appstats.new(offer.id, {
        :start_time => start_time,
        :end_time => end_time,
        :granularity => :daily,
        :stat_types => ['offerwall_views', 'featured_offers_shown', 'display_ads_shown', 'installs_revenue', 'offers_revenue', 'rewards_revenue', 'featured_revenue', 'display_revenue', 'daily_active_users', 'total_revenue', 'arpdau']})
      appstats_data[offer.id] = {
        :arpdau => appstats.stats['arpdau'].sum.to_f / appstats.stats['arpdau'].length.to_f,
        :offerwall_ecpm => appstats.stats['rewards_revenue'].sum.to_f / (appstats.stats['offerwall_views'].sum / 1000.0),
        :featured_ecpm => appstats.stats['featured_revenue'].sum.to_f / (appstats.stats['featured_offers_shown'].sum / 1000.0),
        :display_ecpm => appstats.stats['display_revenue'].sum.to_f / (appstats.stats['display_ads_shown'].sum / 1000.0),
      }

      partner_program_metadata[offer.id] = {
        'icon_url'           => offer.get_icon_url,
        'offer_name'         => offer.name_with_suffix,
        'price'              => NumberHelper.number_to_currency(offer.price / 100.0),
        'payment'            => NumberHelper.number_to_currency(offer.payment / 100.0),
        'balance'            => NumberHelper.number_to_currency(offer.partner.balance / 100.0),
        'conversion_rate'    => NumberHelper.number_to_percentage((offer.conversion_rate || 0) * 100.0, :precision => 1),
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
      partner_revenue_stats[offer.partner.id] += partner_program_stats[offer.id]['publisher_revenue']
    end

    partner_program_stats_adv = partner_program_stats.sort do |s1, s2|
      NumberHelper.currency_to_number(s2[1]['spend']) <=> NumberHelper.currency_to_number(s1[1]['spend'])
    end

    return partner_program_metadata, partner_program_stats_adv, partner_revenue_stats, partner_names, appstats_data
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
    data = ["Offer,Publisher_name,Spend,Conversions,Store_rank,Price,Payment,Balance,Platform,CVR,Published_offers,ARPDAU,Offerwall_ecpm,Featured_ecpm,Display_ecpm,Gross_revenue,Publisher_revenue,Publisher_total_revenue,Publisher_pending_earnings,Featured,Rewarded,Offer_type,Sales_rep"]
    @partner_program_metadata, @partner_program_stats, @partner_revenue_stats, @partner_names, @appstats_data = get_stats(@start_time, @end_time)
    @partner_program_stats.each do |offer_id, stats|
      metadata = @partner_program_metadata[offer_id]
      line = [
        metadata['offer_name'].gsub(/[,]/,' '),
        @partner_names[metadata['partner_id']].gsub(/[,]/,' '),
        stats['spend'].to_s.gsub(/[,]/,''),
        stats['conversions'].to_s.gsub(/[,]/,''),
        metadata['overall_store_rank'].to_s.gsub(/[,]/,''),
        metadata['price'].to_s.gsub(/[,]/,''),
        metadata['payment'].to_s.gsub(/[,]/,''),
        metadata['balance'].to_s.gsub(/[,]/,''),
        metadata['platform'],
        metadata['conversion_rate'],
        stats['published_offers'].to_s.gsub(/[,]/,''),
        NumberHelper.number_to_currency(@appstats_data[offer_id][:arpdau] / 100.0, :precision => 4, :delimiter => ''),
        NumberHelper.number_to_currency(@appstats_data[offer_id][:offerwall_ecpm] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@appstats_data[offer_id][:featured_ecpm] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@appstats_data[offer_id][:display_ecpm] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(stats['gross_revenue'] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(stats['publisher_revenue'] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@partner_revenue_stats[metadata['partner_id']] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(metadata['partner_pending_earnings'] / 100.0, :delimiter => ''),
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
