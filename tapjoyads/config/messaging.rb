#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
  #s.destination :orders, '/queue/Orders'
  #s.filter :some_filter, :only=>:orders
  #s.processor_group :group1, :order_processor
  
  s.destination :hello_world, RUN_MODE_PREFIX + 'HelloWorld'
  s.destination :getad_stats, RUN_MODE_PREFIX + 'GetadStats'
  s.destination :adshown_stats, RUN_MODE_PREFIX + 'AdshownStats'
  s.destination :adshown_request, RUN_MODE_PREFIX + 'AdshownRequest'
end