require 'test_helper'

class PointPurchasesTest < ActiveSupport::TestCase

  test "hash method" do
    assert_equal "test string".hash, -1736596589, "Ruby upgrade? Hash must match, or else dynamic_domain_name will be wrong."
    assert_equal "foo.bar".hash, -230128492
  end
end
