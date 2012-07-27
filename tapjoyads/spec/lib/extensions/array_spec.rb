require 'spec_helper'

describe Array do
  before :each do
    @elements = [:a, :b, :c]
    @weights = [3, 1, 6]
  end

  context '#weighted_rand' do
    it "should follow probability distribution" do
      iterations = 100000
      counts = {:a => 0, :b => 0, :c => 0}
      iterations.times do |i|
        element = @elements.weighted_rand(@weights)
        counts[element] += 1
      end

      probabilities = {}
      probabilities[:a] = counts[:a]/iterations.to_f
      probabilities[:b] = counts[:b]/iterations.to_f
      probabilities[:c] = counts[:c]/iterations.to_f

      tolerance = 0.0035
      probabilities[:a].should be_within(tolerance).of(0.3)
      probabilities[:b].should be_within(tolerance).of(0.1)
      probabilities[:c].should be_within(tolerance).of(0.6)
    end
  end
end
