require 'spec_helper'

describe FakeSdb do
  let(:subject) {
    db = FakeSdb.new
    db.put_attributes('foo', 'one', {
      'ping' => ['pong'],
      'bing' => ['bong'],
      'sing' => ['song']
    })

    db.put_attributes('foo', 'two', {
      'ping' => ['wrong'],
      'bing' => ['wrong'],
      'sing' => ['wrong']
    })

    db.put_attributes('foo', 'three', {
      'ping' => ['pong'],
      'bing' => ['wrong'],
      'sing' => ['wrong']
    })

    db.put_attributes('foo', 'four', {
      'ping' => ['pong'],
      'bing' => ['bong'],
      'sing' => ['wrong']
    })

    # For null querying
    db.put_attributes('foo', 'five', {
      'rhyme' => ['fail']
    })

    db.put_attributes('ints', 'one', {
      'val' => [1]
    })

    db.put_attributes('ints', 'two', {
      'val' => [2]
    })

    db.put_attributes('ints', 'three', {
      'val' => [3]
    })

    db.put_attributes('ints', 'four', {
      'val' => [4]
    })

    db.put_attributes('ints', 'five', {
      'val' => [5]
    })

    db
  }

  let(:data) {
    subject.instance_variable_get(:@fake_sdb_data)
  }

  describe 'with no conditions' do
    it 'returns all rows' do
      rows = subject.select('select * from foo')[:items]
      rows.size.should == 5
    end

    it 'supports ordering and limiting' do
      rows = subject.select('select * from ints order by val desc')[:items]
      rows.collect(&:keys).flatten.should == %w{five four three two one}

      rows = subject.select('select * from ints order by val asc')[:items]
      rows.collect(&:keys).flatten.should == %w{one two three four five}

      rows = subject.select('select * from ints order by val desc limit 2')[:items]
      rows.collect(&:keys).flatten.should == %w{five four}
    end
  end

  describe 'with a single condition' do
    it 'handles equality' do
      rows = subject.select(
        %{select * from foo where ping = 'pong'}
      )[:items]

      # This output format seems delicate, so let's
      # be sure we neeeever break it
      # rows are returned in an undefined order
      # which makes this spec a little ridiculous
      rows.size.should == 3
      rows.collect(&:keys).flatten.sort.should == %w{four one three}
      rows.sort { |a, b| a.keys[0] <=> b.keys[0] }.should == [{
        'four' => data['foo']['four']
      }, {
        'one' => data['foo']['one']
      }, {
        'three' => data['foo']['three']
      }]
    end

    it 'handles inequality' do
      rows = subject.select(
        %{select * from foo where ping != 'pong'}
      )[:items]

      rows.size.should == 1
      rows.collect(&:keys).flatten.sort.should == %w{two}

      rows = subject.select(
        %{select * from ints where val >= 4}
      )[:items]

      rows.size.should == 2
      rows.collect(&:keys).flatten.sort.should == %w{five four}
    end

    it 'handles "is null" and "is not null"' do
      rows = subject.select(
        %{select * from foo where ping is not null}
      )[:items]

      rows.size.should == 4
      rows.collect(&:keys).flatten.sort.should == %w{four one three two} # alphabetical whoa

      rows = subject.select(
        %{select * from foo where ping is null}
      )[:items]

      rows.size.should == 1
      rows.collect(&:keys).flatten.should == %w{five}
    end

    it 'handles negative numbers' do
      subject.put_attributes('ints', 'negative_two', {
      'val' => [-2]
      })

      subject.put_attributes('ints', 'negative_one', {
        'val' => [-1]
      })

      rows = subject.select(
        %{select * from ints where val <= 0}
      )[:items]

      rows.collect(&:keys).flatten.sort.should == %w{negative_one negative_two}
    end
  end

  describe 'with one `and` operator' do
    it 'handles equality' do
      rows = subject.select(
        %{select * from foo where ping = 'pong' and bing = 'bong'}
      )[:items]

      rows.size.should == 2
      rows.collect(&:keys).flatten.sort.should == %w{four one}

      rows = subject.select(
        %{select * from ints where val = 4}
      )[:items]

      rows.size.should == 1
      rows.collect(&:keys).flatten.sort.should == %w{four}
    end

    it 'can mix equality and inequality' do
      rows = subject.select(
        %{select * from foo where ping = 'pong' and bing != 'bong'}
      )[:items]

      rows.size.should == 1

      rows = subject.select(
        %{select * from ints where val < 2 or val > 4}
      )[:items]

      rows.collect(&:keys).flatten.sort.should == %w{five one}
    end

    it 'can count' do
      result = subject.select(%{select count(*) from foo where ping = 'pong' and bing = 'bong'})
      result[:items][0]['Domain']['Count'].should == [2]
    end

    it 'handles negative numbers' do
      subject.put_attributes('ints', 'negative_two', {
      'val' => [-2]
      })

      subject.put_attributes('ints', 'negative_one', {
        'val' => [-1]
      })

      rows = subject.select(
        %{select * from ints where val <= 0 and val > -2}
      )[:items]

      rows.collect(&:keys).flatten.sort.should == %w{negative_one}
    end
  end

  describe 'with one `or` operator' do
    it 'handles equality' do
      rows = subject.select(
        %{select * from foo where ping = 'wrong' or sing = 'song'}, nil, nil
      )[:items]

      rows.size.should == 2
      rows.collect(&:keys).flatten.sort.should == %w{one two}
    end

    it 'handles null comparison' do
      rows = subject.select(
        %{select * from foo where ping = 'wrong' or ping is null}
      )[:items]

      rows.size.should == 2
      rows.collect(&:keys).flatten.sort.should == %w{five two}
    end

    it 'can mix equality and inequality' do
      rows = subject.select(
        %{select * from foo where ping = 'pong' or bing != 'bong'}
      )[:items]

      rows.size.should == 4
    end

    it 'can count' do
      result = subject.select(%{select count(*) from foo where ping = 'pong' or bing != 'bong'})
      result[:items][0]['Domain']['Count'].should == [4]
    end
  end

  describe 'with parentheses' do
    it 'handles the simplest case' do
      rows = subject.select(
        %{select * from foo where (ping = 'pong')}
      )[:items].collect(&:keys).flatten.sort.should == %w{four one three}
    end

    it 'disambiguates queries' do
      subject.select(
        %{select * from foo where (ping = 'pong' and bing = 'bong') or sing = 'wrong'}
      )[:items].size.should == 4

      subject.select(
        %{select * from foo where ping = 'pong' and (bing = 'bong' or sing = 'wrong')}
      )[:items].size.should == 2
    end
  end

  describe 'result set' do
    it 'is safe to modify' do
      record = subject.select(
        %{select * from foo where ping = 'pong' and sing = 'song'}, nil, nil
      )[:items].first

      # add a column
      record['one']['thing'] = 'thong'
      record['one'].delete('ping')

      data['foo']['one'].should_not have_key('thing')
      data['foo']['one'].should have_key('ping')

      record['one'].should have_key('thing')
      record['one'].should_not have_key('ping')
    end

    it 'can be yielded to a block individually' do
      sum = 0
      subject.select('select * from ints') { |row| sum += row['val'][0] }
      sum.should == 15
    end
  end

  describe 'inserted data' do
    it 'may be modified after insertion' do
      record = {'key' => ['val']}

      subject.put_attributes('safe', 'data', {
        'key' => 'val'
      })

      record['key'][0] << 'OMG MODIFIED'

      subject.select('select * from safe')[:items][0]['data'].should == {'key' => 'val'}
      record.should == {'key' => ['valOMG MODIFIED']}
    end
  end
end
