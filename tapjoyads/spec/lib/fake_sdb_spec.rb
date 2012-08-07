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

    db
  }

  let(:data) {
    subject.instance_variable_get(:@fake_sdb_data)
  }

  describe 'query on a single column' do
    describe 'with a single condition' do
      it 'handles equality' do
        rows = subject.select(
          %{select * from foo where ping = 'pong'}, nil, nil
        )[:items]

        # This output format seems delicate, so let's
        # be sure we neeeever break it
        rows.size.should == 1
        rows[0].keys.should == ['one']
        rows[0]['one'].should == data['foo']['one']
        rows.should == [{
          'one' => {
            'bing' => ['bong'],
            'sing' => ['song'],
            'ping' => ['pong']
          }
        }]
      end
    end

    describe 'with one `and` operator' do
      it 'handles equality' do
        rows = subject.select(
          %{select * from foo where ping = 'pong' and bing = 'bong'}, nil, nil
        )[:items]

        rows.size.should == 1
        rows[0].keys.should == ['one']
      end
    end
  end
end