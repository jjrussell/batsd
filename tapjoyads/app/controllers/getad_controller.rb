class GetadController < ApplicationController
  def adfonic
    respond_to do |f|
      @tjad = TapjoyAd.new
      @tjad.ClickURL = 'http://sample.com'
      @tjad.Image = '9823897239487239487'
      f.xml {render(:layout => false)}
    end
  end
end
