require 'spec_helper'

describe InvoiceReportGenerator do
  
  let (:report_date) { Date.parse('2012-03-01') }
  
  subject do
    InvoiceReportGenerator.new(report_date)
  end
  
  # Normally, hardcoded array indexing would be a bad thing in a test. In this case, the receiving end of the CSV is
  #  relying on stable ordering, so column indexes are part of the spec.
  describe '#rowify' do
    let (:client) { nil }
    let (:partner) { FactoryGirl.create(:partner, :billing_email => FactoryGirl.generate(:email), :client => client) }
    let (:note_to_client) { nil }
    let (:invoice) { FactoryGirl.create(:order, :payment_method => 1, :partner => partner, :note_to_client => note_to_client) }

    it 'should use Order#id as the legacy invoice number' do
      subject.rowify(invoice)[0].should == invoice.id
    end

    it 'should use fixed values for line number, status, and unit price' do
      subject.rowify(invoice)[1].should == 1
      subject.rowify(invoice)[2].should == 'New'
      subject.rowify(invoice)[7].should == 1
    end

    context 'with no client' do
      let (:client) { nil }

      it 'should list the client ID as "none"' do
        subject.rowify(invoice)[3].should == 'none'
      end
    end

    context 'with a client' do
      let (:client) { FactoryGirl.create(:client) }

      it 'it should list the client ID' do
        subject.rowify(invoice)[3].should == client.id
      end
    end

    context 'with no Order#note_to_client' do
      let (:note_to_client) { nil }

      it 'should list the description as "TapjoyAdsCredit"' do
        subject.rowify(invoice)[5].should == 'TapjoyAdsCredit'
      end
    end

    context 'with an Order#note_to_client' do
      let (:note_to_client) { 'Test note' }

      it 'should populate the description with #note_to_client' do
        subject.rowify(invoice)[5].should == note_to_client
      end
    end
  end

  describe '#trx_date' do
    its(:trx_date) { should == '01-Mar-2012' }
  end

  describe '#date_range' do
    its(:date_range) { subject.min.should == Time.parse('Mar 01 00:00:00 UTC 2012') }
    its(:date_range) { subject.max.should == Time.parse('Mar 02 00:00:00 UTC 2012') }
  end

  describe '#filename' do
    its(:filename) { should == 'ORACLE_AR_INTERFACE_03012012.csv' }
  end
end
