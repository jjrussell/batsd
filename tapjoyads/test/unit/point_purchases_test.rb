require 'test_helper'

class PointPurchasesTest < ActiveSupport::TestCase

  test "hash method" do
    assert_equal "test string".hash, -173659658, "Ruby upgrade? Hash must match, or else dynamic_domain_name will be wrong."
  end
end
