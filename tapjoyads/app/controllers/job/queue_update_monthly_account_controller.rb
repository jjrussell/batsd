class Job::QueueUpdateMonthlyAccountController < Job::SqsReaderController
  
  include NewRelicHelper
  
  def initialize
    super QueueNames::UPDATE_MONTHLY_ACCOUNT
  end
  
private
  
  def on_message(message)
    
    json = JSON.parse(message.to_s)
        
    partner = Partner.find(json['partner_id'])
    month = json['month'].to_i
    year = json['year'].to_i
    
    throw "Partner #{json['partner_id']} not found" unless partner
    
    MonthlyAccounting.update_partner_record(partner.id, { :month => month, :year => year })
    
  end
  
  
end
