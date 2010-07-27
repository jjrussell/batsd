Factory.define :store_click do |click|
  click.key { "#{Factory.next(:udid)}.#{Factory.next(:guid)}" }
end

Factory.define :point_purchase, :class => 'PointPurchases' do |point_purchase|
  point_purchase.key { "#{Factory.next(:udid)}.#{Factory.next(:guid)}" }
end
