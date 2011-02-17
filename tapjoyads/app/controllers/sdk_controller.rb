class SdkController < WebsiteController

  def index
    @iphone_version  =  IPHONE_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
    @android_version = ANDROID_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
  end

  def show
    target =
      case params[:id]
      when 'android-adv'
        ANDROID_CONNECT_SDK
      when 'android-pub'
        ANDROID_OFFERS_SDK
      when 'android-vg'
        ANDROID_VG_SDK
      when 'iphone-adv'
        IPHONE_CONNECT_SDK
      when 'iphone-pub'
        IPHONE_OFFERS_SDK
      when 'iphone-vg'
        IPHONE_VG_SDK
      else
        :index
      end
      redirect_to target
  end
end
