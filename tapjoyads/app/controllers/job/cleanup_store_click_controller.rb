class Job::CleanupStoreClickController < Job::SqsReaderController
  def initialize
    super QueueNames::CLEANUP_STORE_CLICK
  end

  private
  
  def on_message(message)
    date_string = message.to_s
    start_time = Time.parse(date_string).beginning_of_day.to_i
    end_time = start_time + 24.hours
    
    SdbBackup.backup_domain('store-click', 'store-clicks',
        :where => "click_date >= '#{start_time}' and click_date < '#{end_time}'",
        :delete_rows => true, 
        :suffix => "_#{date_string}")
  end
end