class Alert
  attr_accessor :query, :message, :recipients_field, :fields, :recipients, :run_at_hours

  def initialize(alert, time = Time.zone.now)
    @query            = alert['query']
    @message          = alert['message']
    @fields           = alert['fields']
    @recipients_field = alert['recipients_field']
    @recipients       = alert['recipients']
    @run_at_hours     = alert['run_at_hours']

    @time             = time

    prepare_query
  end

  def run
    unless skip?
      begin
        rows = vertica.query(@query).rows
      rescue Vertica::Error::QueryError
        return false
      end

      push(rows) if rows.length > 0
    end
  end

  private

  def skip?
    unless @run_at_hours.blank?
      @run_at_hours.include?(@time.hour)
    end
  end

  def prepare_query
    @query.gsub!('|_HOUR_|', @time.hour.to_s)
  end

  def push(rows)
    if @recipients_field
      direct_recipients = rows.collect {|row| row[@recipients_field.to_sym] }.uniq

      direct_recipients.each do |recipient|
        TapjoyMailer.deliver_alert(self, rows.select {|row| row[@recipients_field.to_sym] == recipient}, recipient)
      end
    else
      TapjoyMailer.deliver_alert(self, rows, recipients)
    end
  end

  def vertica
    @vertica ||= VerticaCluster.get_connection
  end

end
