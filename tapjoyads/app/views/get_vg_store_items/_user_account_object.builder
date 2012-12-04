xml.UserAccountObject do
  xml.TapPoints @point_purchases.points
  xml.CurrencyName @currency.name
  xml.PointsID @point_purchases.get_tapjoy_device_id
end
