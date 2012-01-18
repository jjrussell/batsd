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
        %w(Android iOS All)
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
end
