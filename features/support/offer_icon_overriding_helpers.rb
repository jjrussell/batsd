def ensure_img_src_changes
  old_icon_url = @offer.get_icon_url
  img_src = nil
  retry_on_timeout do
    wait_until do
      # strip out url params... (we don't care about cache-busting timestamp)
      img_src = find("img#icon")['src'].gsub(/\?[^\?]*$/, '')
      img_src != old_icon_url
    end
  end
  img_src.should == @offer.reload.get_icon_url
  yield img_src if block_given?
end
