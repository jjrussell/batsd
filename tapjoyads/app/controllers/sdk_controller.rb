class SdkController < WebsiteController

  layout 'sdks'

  SDKS = {
    'android' => {
      'adv'       => ANDROID_CONNECT_SDK,
      'pub'       => ANDROID_OFFERS_SDK,
      'vg'        => ANDROID_VG_SDK,
      'marmalade' => ANDROID_MARMALADE_EXTENSION,
      'phonegap'  => ANDROID_PHONEGAP_PLUGIN,
      'unity'     => ANDROID_UNITY_PLUGIN,
    },
    'iphone' => {
      'adv'       => IPHONE_CONNECT_SDK,
      'pub'       => IPHONE_OFFERS_SDK,
      'vg'        => IPHONE_VG_SDK,
      'marmalade' => IPHONE_MARMALADE_EXTENSION,
      'phonegap'  => IPHONE_PHONEGAP_PLUGIN,
      'unity'     => IPHONE_UNITY_PLUGIN,
    },
    'windows' => {
      'adv'       => WINDOWS_CONNECT_SDK,
      'pub'       => WINDOWS_OFFERS_SDK,
      'vg'        => WINDOWS_OFFERS_SDK,
    },
  }

  def index
    @iphone_version  =  IPHONE_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
    @android_version = ANDROID_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
    @windows_version = WINDOWS_CONNECT_SDK[/v\d+\.\d+\.\d+\.zip/][0..-5]
  end

  def show
    platform, sdk_type = params[:id].split(/-/)
    sdk_download_link = SDKS[platform] && SDKS[platform][sdk_type]
    redirect_to sdk_download_link || sdk_index_path
  end

  def popup
    render :layout => false
  end

  def license
    render :layout => false
  end
end
