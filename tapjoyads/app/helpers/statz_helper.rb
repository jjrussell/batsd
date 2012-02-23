module StatzHelper
  def property_row(key, value, default_value = nil, value_css_class = '')
    return if value == default_value
    concat("<tr>")
    concat("<td>#{key}</td>")
    concat("<td class = '#{value_css_class}'>#{value}</td>")
    concat("</tr>")
  end

  def filter_options(filter_type)
    options =
      case filter_type
      when :rank
        %w(ranked unranked)
      when :free
        %w(Free Paid)
      when :platform
        %w(Android iOS Windows All)
      when :conversions
        [
          [ "0", "zero_conversions"],
          [ ">0", "nonzero_conversions"],
        ]
      when :spend
        [
          [ "$0.00", "zero_spend"],
          [ ">$0", "nonzero_spend"],
        ]
      when :connects
        [
          [ "0", "zero_connects"],
          [ ">0", "nonzero_connects"],
        ]
      when :published_offers
        [
          [ "0", "zero_published"],
          [ ">0", "nonzero_published"],
        ]
      when :balance
        [
          [">$10k","10000"],
          [">$1k", "1000"],
          [">$0", "0"],
          ["\342\211\244$0","negative"],
        ]
      when :pending_earning
        [
          [">$10k","earning_10k"],
          [">$1k", "earning_1k"],
          [">$0", "earning_zero"],
          ["\342\211\244$0","earning_negative"],
        ]
      when :gross_revenue
        [
          ["$0.00", "zero_gross_revenue"],
          [">$0", "nonzero_gross_revenue"],
        ]
      when :arpdau
        [
          ["$0.0000", "zero_arpdau"],
          [">$0", "nonzero_arpdau"],
        ]
      when :offerwall_ecpm
        [
          ["$0.00", "zero_offerwall_ecpm"],
          [">$0", "nonzero_offerwall_ecpm"],
        ]
      when :featured_ecpm
        [
          ["$0.00", "zero_featured_ecpm"],
          [">$0", "nonzero_featured_ecpm"],
        ]
      when :display_ecpm
        [
          ["$0.00", "zero_display_ecpm"],
          [">$0", "nonzero_display_ecpm"],
        ]
      when :publisher_revenue
        [
          ["$0.00", "zero_publisher_revenue"],
          [">$0", "nonzero_publisher_revenue"],
        ]
      when :publisher_total_revenue
        [
          ["$0.00", "zero_publisher_total_revenue"],
          [">$0", "nonzero_publisher_total_revenue"],
        ]
      when :featured
        [
          ["true", "featured"],
          ["false", "nonfeatured"],
        ]
      when :rewarded
        [
          ["true", "rewarded"],
          ["false", "nonrewarded"],
        ]
      when :offer_type
        %w(App ActionOffer GenericOffer VideoOffer)
      end
    options.unshift([ '-', '' ])
  end

  def get_tr_class(stats, metadata, offer_id = '', appstats_data = {}, partner_revenue_stats = {})
    tr_classes = [
      (stats['spend'] == '$0.00'             ? 'zero_spend'         : 'nonzero_spend'),
      (stats['conversions'] == '0'           ? 'zero_conversions'   : 'nonzero_conversions'),
      (metadata['overall_store_rank'] == '-' ? 'unranked'           : 'ranked'),
      (metadata['price'] == '$0.00'          ? 'free'               : 'paid'),
      metadata['platform'].to_s.downcase,
      (stats['published_offers'] == '0'      ? 'zero_published'     : 'nonzero_published'),
      (stats['gross_revenue'] == '$0.00'     ? 'zero_gross_revenue' : 'nonzero_gross_revenue'),
      (stats['publisher_revenue'] == '$0.00' ? 'zero_publisher_revenue' : 'nonzero_publisher_revenue'),
      (metadata['featured']                  ? 'featured'           : 'nonfeatured'),
      (metadata['rewarded']                  ? 'rewarded'           : 'nonrewarded'),
      metadata['offer_type'].to_s.downcase,
    ]

    if offer_id.present? && appstats_data.present? && partner_revenue_stats.present?
      arpdau         = appstats_data[offer_id][:arpdau]
      offerwall_ecpm = appstats_data[offer_id][:offerwall_ecpm]
      featured_ecpm  = appstats_data[offer_id][:featured_ecpm]
      display_ecpm   = appstats_data[offer_id][:display_ecpm]
      publisher_total_revenue = partner_revenue_stats[metadata['partner_id']]
      publisher_pending_earnings = metadata['partner_pending_earnings'] / 100.0

      more_tr_classes = [
        (arpdau                     == 0     ? 'zero_arpdau'         : 'nonzero_arpdau'),
        (offerwall_ecpm             == 0     ? 'zero_offerwall_ecpm' : 'nonzero_offerwall_ecpm'),
        (featured_ecpm              == 0     ? 'zero_featured_ecpm'  : 'nonzero_featured_ecpm'),
        (display_ecpm               == 0     ? 'zero_display_ecpm'   : 'nonzero_display_ecpm'),
        (publisher_total_revenue    == 0     ? 'zero_publisher_total_revenue' : 'nonzero_publisher_total_revenue'),
        (publisher_pending_earnings >  10000 ? 'earning_10k'         : ''),
        (publisher_pending_earnings >  1000  ? 'earning_1k'          : ''),
        (publisher_pending_earnings >  0     ? 'earning_zero'        : ''),
        (publisher_pending_earnings <= 0     ? 'earning_negative'    : ''),
      ]

      tr_classes += more_tr_classes
    end

    tr_classes.compact.join(' ')
  end
end
