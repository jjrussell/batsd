require 'spec_helper'

describe SimpledbShardedResource do
  # A real model, which interfaces with real simpledb.
  class TestingSharded < SimpledbShardedResource
    self.domain_name = 'testing_sharded'
    self.num_domains = 2

    self.sdb_attr :foo
  end

  describe '.select_all' do
    it 'should return empty array if no matching data' do
      TestingSharded.select_all(:conditions => ["foo = ?", 'test_val']).should == []
    end
  end

end
