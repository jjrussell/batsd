module Simpledb
  class ExpectedAttributeError < RuntimeError; end
  class InvalidOptionsError < RuntimeError; end
  class MultiValuedAttributeError < RuntimeError; end
  class MultipleExistsConditionsError < RuntimeError; end
end
