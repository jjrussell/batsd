xml.VGStoreItemReturnClass do
  xml.VGStoreItemID virtual_good.key
  xml.AppleProductID virtual_good.apple_id
  xml.Price virtual_good.price
  xml.Name virtual_good.name
  xml.Description virtual_good.description
  xml.VGStoreItemTypeName virtual_good.title
  xml.AttributeValues do
    virtual_good.extra_attributes.each do |key, value|
      xml.VGStoreItemAttributeValueReturnClass do
        xml.AttributeType key
        xml.AttributeValue value
      end
    end
    xml.VGStoreItemAttributeValueReturnClass do
      xml.AttributeType 'quantity'
      xml.AttributeValue point_purchases.get_virtual_good_quantity(virtual_good.key)
    end
  end
  xml.MaxNumberOwned virtual_good.max_purchases
  xml.NumberOwned point_purchases.get_virtual_good_quantity(virtual_good.key)
  xml.ThumbImageURL virtual_good.icon_url
  xml.DatafileURL virtual_good.data_url if virtual_good.has_data
  xml.FileSize virtual_good.file_size
  xml.DataHash virtual_good.data_hash || "0"
end
