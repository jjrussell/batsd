class OneOffs
  def self.populate_offers_app_metadata_id
    Offer.connection.execute("update offers set app_metadata_id =
      (select app_metadata_id from app_metadata_mappings where app_id = item_id)
      where item_type = 'App' and item_id in (select app_id from app_metadata_mappings)")
    Offer.connection.execute("update offers set app_metadata_id =
      (select app_metadata_id from app_metadata_mappings map, action_offers ao where map.app_id = ao.app_id and ao.id = item_id)
      where item_type = 'ActionOffer' and item_id in (select ao.id from app_metadata_mappings map, action_offers ao where map.app_id = ao.app_id and ao.id = item_id)")
  end
end
