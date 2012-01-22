require 'spec_helper'

describe Downloader do
  before(:each) do
    Downloader.backend = FakeDownloader
  end

  describe '.get' do
    context 'given a valid request' do
      context 'when the body is returned' do
        let(:response) { Downloader.get('http://working.com/') }

        it 'is the body as a string' do
          response.should == 'GET http://working.com/'
        end
      end

      context 'when the response is returned' do
        let(:response) { Downloader.get('http://working.com/', :return_response => true) }

        it 'has the body' do
          response.should respond_to(:body)
        end

        it 'has the code' do
          response.should respond_to(:code)
        end
      end
    end

    context 'given a valid request with a bad response' do
      context 'when the body is returned' do
        let(:response) { Downloader.get('http://broken.com/') }

        it 'has a nil body' do
          response.should_not be
        end
      end

      context 'when the response is returned' do
        let(:response) { Downloader.get('http://broken.com/', :return_response => true) }

        it 'has a nil body' do
          response.body.should_not be
        end

        it 'still has a code' do
          response.code.should be
        end
      end
    end

    context 'given a request that times out' do
      it 'raises a Timeout::Error' do
        expect { Downloader.get('http://timeout.com/') }.to raise_error(Timeout::Error)
      end
    end

    context 'given a request that can\'t find a socket' do
      it 'raises a SocketError' do
        expect { Downloader.get('http://nosocket.com/') }.to raise_error(SocketError)
      end
    end

    context 'given a request that can\'t resolve' do
      it 'raises a Errno::ECONNREFUSED' do
        expect { Downloader.get('http://refused.com/') }.to raise_error(Errno::ECONNREFUSED)
      end
    end
  end

  describe '.post' do
    context 'given a valid request' do
      context 'when the body is returned' do
        let(:response) { Downloader.post('http://working.com/', {}) }

        it 'is the body as a string' do
          response.should == 'POST http://working.com/'
        end
      end

      context 'when the response is returned' do
        let(:response) { Downloader.post('http://working.com/', {}, :return_response => true) }

        it 'has the body' do
          response.should respond_to(:body)
        end

        it 'has the code' do
          response.should respond_to(:code)
        end
      end
    end

    context 'given a valid request with a bad response' do
      context 'when the body is returned' do
        let(:response) { Downloader.post('http://broken.com/', {}) }

        it 'has a nil body' do
          response.should_not be
        end
      end

      context 'when the response is returned' do
        let(:response) { Downloader.post('http://broken.com/', {}, :return_response => true) }

        it 'has a nil body' do
          response.body.should_not be
        end

        it 'still has a code' do
          response.code.should be
        end
      end
    end

    context 'given a request that times out' do
      it 'raises a Timeout::Error' do
        expect { Downloader.post('http://timeout.com/', {}) }.to raise_error(Timeout::Error)
      end
    end

    context 'given a request that can\'t find a socket' do
      it 'raises a SocketError' do
        expect { Downloader.post('http://nosocket.com/', {}) }.to raise_error(SocketError)
      end
    end

    context 'given a request that can\'t resolve' do
      it 'raises a Errno::ECONNREFUSED' do
        expect { Downloader.post('http://refused.com/', {}) }.to raise_error(Errno::ECONNREFUSED)
      end
    end
  end

  describe '.get_strict' do
    context 'given a valid request' do
      let(:response) { Downloader.get_strict('http://working.com/') }

      it 'has a body' do
        response.body.should be
      end

      it 'has a code' do
        response.code.should be
      end
    end

    context 'given a valid request with an invalid response' do
      it 'raises an error' do
        expect { Downloader.get_strict('http://broken.com/', {}) }.to raise_error
      end
    end
  end

  describe '.get_with_retry' do
    context 'given a valid request' do
      let(:response) { Downloader.get_with_retry('http://working.com/') }

      it 'has a body' do
        response.body.should be
      end

      it 'has a code' do
        response.code.should be
      end
    end

    context 'given a valid request with an invalid response' do
      it 'queues the request in sqs' do
        Sqs.expects(:send_message)
        Downloader.get_with_retry('http://broken.com/')
      end

      it 'has a nil response' do
        Downloader.get_with_retry('http://broken.com/').should_not be
      end
    end
  end
end
