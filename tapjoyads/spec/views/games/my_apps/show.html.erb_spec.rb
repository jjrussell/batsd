require 'spec_helper'

describe "/games/my_apps/show" do
  before(:each) do
    render 'games/my_apps/show'
  end

  #Delete this example and add some real ones or delete this file
  it "should tell you where to find the file" do
    response.should have_tag('p', %r[Find me in app/views/games/my_apps/show])
  end
end
