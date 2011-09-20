require File.dirname(__FILE__) + '/../test_helper'

class StringTest < Test::Unit::TestCase

  def test_matz_silly_hash
    if RUBY_VERSION >= '1.9'
      known_values = {
        "amir" => -706469127,
        "tapjoy" => 1527460358,
        "Tapjoy" => -1890408217,
        "California" => 1130092548,
        "a" => 100,
        "A" => 67,
      }.each do |k,v|
        assert_equal k.matz_silly_hash, v
      end
    else
      1000.times do
        test_string = UUIDTools::UUID.random_create.to_s
        assert_equal test_string.matz_silly_hash, test_string.hash
      end
    end
  end
end
