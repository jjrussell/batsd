require 'spec_helper'

describe Array do

  describe '#weighted_rand' do

    def call_weighted_rand(values, weights, iterations=100)
      tally = {}
      iterations.times do
        val = values.weighted_rand(weights)
        tally[val] ||= 0
        tally[val] +=  1
      end
      results = {}
      tally.each_pair do |value, count|
        results[value] = tally[value].to_f/iterations.to_f
      end
      results
    end

    context 'given a normal random distribution' do
      let(:iterations) { 100 }
      before(:each) do
        Kernel.stub(:rand).and_return(*(0...iterations).map { |i| i.to_f/iterations.to_f } )
      end

      context 'given weights whose sum is 10' do
        let(:elements) do
          [[:a, 1], [:b, 2], [:c, 7]]
        end
        let(:values)        { elements.map {|tuple| tuple[0]} }
        let(:weights)       { elements.map {|tuple| tuple[1]} }
        let(:distribution)  { call_weighted_rand(values, weights, iterations) }
        let(:tolerance)     { 0.005 }

        it 'an element with a weight of 1 is returned 1/10th  of the time' do
          distribution[:a].should be_within(tolerance).of(1.0/10.0)
        end

        it 'an element with a weight of 2 is returned 1/5th   of the time' do
          distribution[:b].should be_within(tolerance).of(1.0/5.0)
        end

        it 'an element with a weight of 7 is returned 7/10ths of the time' do
          distribution[:c].should be_within(tolerance).of(7.0/10.0)
        end
      end
    end
  end

end
