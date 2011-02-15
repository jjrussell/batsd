class SdkController < WebsiteController
  layout 'tabbed'
  filter_access_to :all

  def index
    @iphone_version  =  IPHONE_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
    @android_version = ANDROID_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
  end

  def show
    target =
      case params[:id]
      when 'android-connect'
        ANDROID_CONNECT_SDK
      when 'android-offers'
        ANDROID_OFFERS_SDK
      when 'android-vg'
        ANDROID_VG_SDK
      when 'iphone-connect'
        IPHONE_CONNECT_SDK
      when 'iphone-offers'
        IPHONE_OFFERS_SDK
      when 'iphone-vg'
        IPHONE_VG_SDK
      else
        :index
      end
      redirect_to target
  end
end
