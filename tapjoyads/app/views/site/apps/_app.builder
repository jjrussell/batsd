xml.app do
  xml.id app.key
  xml.name app.get('name')
  xml.description app.get('description')
  xml.icon "http://ws.tapjoyads.com/get_app_image/icon?app_id=#{app.key}&img=1"
  xml.tag!('store-url', app.get('store_url'))
  xml.price app.get('price')
  xml.platform '' # TODO: get real platform
  xml.tag!('store-id', '') # TODO: get real store-id
  #xml.color app.get('color') #TODO: this line is giving error for most of scenarios
end