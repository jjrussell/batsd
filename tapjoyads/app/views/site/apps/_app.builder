xml.app do
  xml.id app.key
  xml.name app.get('name')
  xml.description app.get('description')
  xml.icon "http://ws.tapjoyads.com/get_app_image/icon?app_id=#{app.key}&img=1"
  xml.tag!('store-url', app.get('store_url'))
  xml.price app.get('price')
  xml.platform '' # TODO: get real platform
  xml.tag!('store-id', '') # TODO: get real store-id
  xml.color '' #TODO: change to app.get('color') once import_ms_sql fills color with valid values
  xml.progress ''
  xml.status app.get('payment_for_install') == '0' ? 'off' : 'on'
  xml.tag!('bid-price', app.get('payment_for_install'))
end