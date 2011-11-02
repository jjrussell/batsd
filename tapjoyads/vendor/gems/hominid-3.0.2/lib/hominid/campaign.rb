module Hominid
  module Campaign
   
    # Find a campaign by id
    def find_campaign_by_id(campaign_id)
      campaigns({:campaign_id => campaign_id})['data']
    end
    
    # Find a campaign by web_id
    def find_campaign_by_web_id(campaign_web_id)
      campaigns['data'].find {|c| c["web_id"] == campaign_web_id}
    end
    
    # Find a campaign by name
    def find_campaigns_by_title(campaign_title, *args)
      campaigns({:title => campaign_title}, *args)['data']
    end
    
    # Find campaigns by list name
    def find_campaigns_by_list_name(list_name, *args)
      campaigns({:list_id => find_list_id_by_name(list_name)}, *args)['data']
    end
    
    # Find campaigns by list id
    def find_campaigns_by_list_id(list_id, *args)
      campaigns({:list_id => list_id}, *args)['data']
    end
    
    # Find campaigns by type
    def find_campaigns_by_type(campaign_type, *args)
      campaigns({:type => campaign_type}, *args)['data']
    end
    
  end
end