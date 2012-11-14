shared_examples_for "a pageable resource" do
  it 'must allow the definition of before filters' do
    described_class.should respond_to :before_filter
  end

  it 'can define a pageable resource' do
    described_class.should respond_to :pageable_resource
  end

  describe '.collection' do
    it 'is a symbol corresponding to an instance variable available in aggregate controller actions' do
      described_class.collection.should be_a Symbol
    end
  end

  let(:resource) do
    mock 'Resource',
      :total_entries => 1,
      :per_page      => 1,
      :current_page  => 1,
      :paginate      => mock('Paginated Data', :all => [])
  end
  describe '#page_results' do
    before(:each) do
      described_class.stub(:valid_action?).and_return(true)
      controller.stub(:resource).and_return(resource)
    end

    it 'paginates the resource' do
      resource.should_receive :paginate
      controller.page_results
    end

    it 'sets the pagination info' do
      expect{controller.page_results}.to change{controller.pagination_info}
    end
  end

  describe '#resource' do
    it 'is the instance variable encapsulating the pageable resource within the controller' do
      controller.resource.should be controller.send(:instance_variable_get, :"@#{controller.class.collection}")
    end
  end

  describe '#run_query!' do
    let(:per_page)    { 1 }
    let(:page_number) { 1 }
    before(:each) do
      controller.stub(:per_page).and_return(per_page)
      controller.stub(:page_number).and_return(page_number)
      controller.stub(:resource).and_return(resource)
    end

    it 'delegates :page to will_paginate using #page_number' do
      resource.should_receive(:paginate).with(hash_including(:page => page_number))
      controller.run_query!
    end

    it 'delegates :per_page to will_paginate using #per_page' do
      resource.should_receive(:paginate).with(hash_including(:per_page => per_page))
      controller.run_query!
    end
  end

  describe '#page_number' do
    context 'given no params have been specified' do
      it 'uses the defaults' do
        controller.page_number.should == described_class.paging_options[:start_page]
      end
    end

    context 'given params have been specified' do
      let(:specified_page) { 100 }
      it 'uses the specified :page param' do
        controller.stub(:params).and_return(:page => specified_page)
        controller.page_number.should == specified_page
      end
    end
  end

  describe '#per_page' do
    context 'given no params have been specified' do
      it 'uses the defaults' do
        controller.per_page.should == described_class.paging_options[:per_page]
      end
    end

    context 'given params have been specified' do
      let(:specified_per_page) { 100 }
      it 'uses the specified :per_page param' do
        controller.stub(:params).and_return(:per_page => specified_per_page)
        controller.per_page.should == specified_per_page
      end
    end
  end
end
