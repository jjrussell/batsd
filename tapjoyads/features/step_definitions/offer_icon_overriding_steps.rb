Given /^I have uploaded an icon$/ do
  @offer.override_icon!(File.open(file_for("Icon")).read)
end

When /^I attach the icon$/ do
  browser = page.driver.browser
  browser.switch_to.frame("icon_upload")
  attach_file("offer_upload_icon", file_for("Icon"))
  browser.switch_to.default_content
end

When /^I remove the icon$/ do
  browser = page.driver.browser
  browser.switch_to.frame("icon_upload")
  click_link "Remove"
  browser.switch_to.alert.accept
  browser.switch_to.default_content
end

When /^I submit the icon form$/ do
  browser = page.driver.browser
  browser.switch_to.frame("icon_upload")
  click_button "Upload"
  browser.switch_to.default_content
end

Then /^the icon image should change to the new icon$/ do
  ensure_img_src_changes { |img_src| Downloader.get(img_src).should == @offer.icon_s3_object('57').read }
end

Then /^the icon image should change to the default$/ do
  ensure_img_src_changes
end
