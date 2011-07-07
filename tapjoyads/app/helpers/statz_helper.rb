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
      when :check_zero
        %w(0 >0)
      when :balance
        [
          [">$10k","10000"],
          [">$1k", "1000"],
          [">$0", "0"],
          ["\342\211\244$0","negative"],
        ]
      when :money
        %w($0.00 >$0)
      when :featured
        %w(true false)
      when :offer_type
        %w(App ActionOffer GenericOffer)
      end
    options.unshift([ '-', '' ])
  end
end
