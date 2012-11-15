require 'spec_helper'

describe ConversionRate do
  it { should belong_to(:currency) }
end
