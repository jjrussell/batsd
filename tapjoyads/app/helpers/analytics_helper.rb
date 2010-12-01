module AnalyticsHelper
  def apsalar_image_tag(thumb, large=nil)
    thumb_image = APSALAR_URL + '/wp-content/themes/apsalar/images/' + thumb
    if large.nil?
      image_tag(thumb_image, :class => 'apsalar_thumbnail')
    else
      large_image = APSALAR_URL + '/wp-content/themes/apsalar/images/' + large
      link_to(image_tag(thumb_image, :class => 'apsalar_thumbnail'), large_image, :class => 'single_image')
    end
  end
end
