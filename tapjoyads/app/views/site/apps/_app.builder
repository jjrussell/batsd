xml.app do
  xml.id app.key
  xml.name app.get('name')
  xml.description app.get('description')
  xml.icon "http://ws.tapjoyads.com/get_app_image/icon?app_id=#{app.key}&img=1"
end