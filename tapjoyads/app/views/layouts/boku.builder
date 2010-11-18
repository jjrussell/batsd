xml.instruct! :xml, :version => '1.0', :encoding => 'ISO-8859-1'
xml.tag! 'callback-ack' do
  xml.tag! 'trx-id', @trx_id
  xml.status 'OK', :code => '0'
end
