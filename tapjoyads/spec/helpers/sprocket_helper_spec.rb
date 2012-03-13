require File.dirname(__FILE__) + '/../spec_helper'

describe SprocketHelper do
  before :each do
    Sprockets::Tj.assets.append_path "#{Rails.root}/spec/assets/javascripts"
    Sprockets::Tj.assets.append_path "#{Rails.root}/spec/assets/stylesheets"
  end
  context "with is_cached set to false" do
    before :all do
      Sprockets::Tj.is_cached = false
    end

    context "with debug set to true" do
      before :all do
        Sprockets::Tj.debug = true
      end

      describe "#js_tag" do
        it "should return a list of script tags" do
          tags = helper.js_tag("test-master.js")
          tags.should match /test1\.js/
          tags.should match /test2\.js/
          tags.should match /test3\.js/
          tags.should match /test-master\.js/
        end
      end
      describe "#css_tag" do
        it "should return a list of style tags" do
          tags = helper.css_tag("test-master.css")
          tags.should match /style1\.css/
          tags.should match /style2\.css/
          tags.should match /style3\.css/
          tags.should match /test-master\.css/
        end
      end

    end

    context "with debug set to false" do
      before :all do
        Sprockets::Tj.debug = false
      end
      describe "#js_tag" do
        it "should return a single compiled script tag" do
          tag = helper.js_tag("test-master.js")
          tag.should_not match /test1|test2|test3/
          tag.should match /test-master\.js/
        end
      end
      describe "#css_tag" do
        it "should return a single compiled style tag" do
          tag = helper.css_tag("test-master.css")
          tag.should_not match /style1|style2|style3/
          tag.should match /test-master\.css/
        end
      end
    end

  end
end
