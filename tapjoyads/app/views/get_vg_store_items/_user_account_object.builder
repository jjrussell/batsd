xml.UserAccountObject do
  xml.TapPoints @point_purchases.points
  xml.CurrencyName @currency.name
  xml.PointsID @point_purchases.get_udid
end
