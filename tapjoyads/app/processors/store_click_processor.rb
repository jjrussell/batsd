class StoreClickProcessor < ApplicationProcessor
  
  subscribes_to :store_click
  
  def on_message(message)
    click = StoreClick.deserialize(message)
    click.put('from_queue', '1')
    click.save
  end
  
end