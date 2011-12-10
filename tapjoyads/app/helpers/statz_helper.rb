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
      when :revenue
        [
          ["$0.00", "zero_revenue"],
          [">$0", "nonzero_revenue"],
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
