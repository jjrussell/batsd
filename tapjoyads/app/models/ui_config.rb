class UiConfig

  def self.is_fb_signup_hidden
    Mc.distributed_get('tjm.ui.hide_fb_signup')
  end

  def self.hide_fb_signup
    Mc.distributed_put('tjm.ui.hide_fb_signup', true)
  end

  def self.show_fb_signup
    Mc.distributed_delete('tjm.ui.hide_fb_signup')
  end

end
