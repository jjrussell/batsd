require 'test_helper'

class TaggingTest < ActiveSupport::TestCase
  should_belong_to :post
  should_belong_to :tag
end
