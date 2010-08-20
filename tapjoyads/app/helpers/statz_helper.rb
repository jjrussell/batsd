module StatzHelper
  def property_row(key, value, default_value = nil, value_css_class = '')
    return if value == default_value
    concat("<tr>")
    concat("<td>#{key}</td>")
    concat("<td class = '#{value_css_class}'>#{value}</td>")
    concat("</tr>")
  end
end
