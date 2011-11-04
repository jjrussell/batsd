class SdkController < WebsiteController

  layout 'sdks'

  def index
    @iphone_version  =  IPHONE_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
    @android_version = ANDROID_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
    @windows_version = WINDOWS_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
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
      when 'android-unity'
        ANDROID_UNITY_PLUGIN
      when 'android-marmalade'
        ANDROID_MARMALADE_EXTENSION
      when 'iphone-adv'
        IPHONE_CONNECT_SDK
      when 'iphone-pub'
        IPHONE_OFFERS_SDK
      when 'iphone-vg'
        IPHONE_VG_SDK
      when 'iphone-unity'
        IPHONE_UNITY_PLUGIN
      when 'iphone-marmalade'
        IPHONE_MARMALADE_EXTENSION
      when 'windows-adv'
        WINDOWS_CONNECT_SDK
      when 'windows-pub'
        WINDOWS_OFFERS_SDK
      when 'windows-vg'
        WINDOWS_OFFERS_SDK
      else
        sdk_index_path
      end
      redirect_to target
  end

  def popup
    render :layout => false
  end

  def license
    render :layout => false
  end
end
