module GetOffersHelper
  
  def get_previous_link
    return nil if @start_index == 0
    
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['start'] = [@start_index - @max_items, 0].max
    link_to("Previous #{@max_items}", "/get_offers/webpage?#{tmp_params.to_query}", :onclick => "this.className = 'clicked';")
  end
  
  def get_next_link
    return nil if @more_data_available < 1
    
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['start'] = @start_index + @max_items
    link_to("Next #{[@more_data_available, @max_items].min}", "/get_offers/webpage?#{tmp_params.to_query}", :onclick => "this.className = 'clicked';")
  end
  
end
