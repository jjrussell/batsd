class GetadController < ApplicationController
  def adfonic
    respond_to do |f|  
      @ad_return_obj = TapjoyAd.new
      @ad_return_obj.ClickURL = 'http://sample.com'
      @ad_return_obj.Image = '9823897239487239487'
      f.xml {render(:partial => 'tapjoy_ad')}
    end
  end
  
  def crisp
    
  end
  
end
