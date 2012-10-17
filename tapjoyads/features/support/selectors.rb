def selector_for(name)
  case name
  when 'callback URL field' 
    '#currency_callback_url'
  when 'conversion rate field'
    '#currency_conversion_rate'
  when 'currency name field' 
    '#currency_name'
  else
    raise "no selector for #{name}"
  end
end
