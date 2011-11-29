class Tools::SupportRequestsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def mass_resolve
    @request_not_awarded = []
    @request_successfully_awarded = 0
    return if params[:upload_support_requests].blank?
    file_contents = params[:upload_support_requests].read
    if file_contents.blank?
      flash[:error] = 'The given file was empty'
      return
    end

    first_row = true
    column_for_support_request = 0
    file_contents.each do |row|
      begin
        all_columns = row.split(',').map{ |element| element.strip }
        next if all_columns.empty?
        if first_row
          first_row = false
          column_for_support_request = all_columns.index{|column| column.downcase == 'support request'}
          if column_for_support_request.nil?
            column_for_support_request = 0
          else
            next
          end
        end

        support_request_id = all_columns[column_for_support_request]
        raise 'No valid support request' if support_request_id.nil? or support_request_id.empty?
        support_request = SupportRequest.new(:key => support_request_id)
        raise "Invalid support_request_id: #{support_request_id}" if support_request.new_record?
        raise "Unable to find the click associated with the request" if support_request.click_id.nil?
        click = Click.new(:key => support_request.click_id)
        raise "Invalid click id: #{support_request.click_id} for the given support request: #{support_request.id}" if click.new_record?

        click.resolve!
        @request_successfully_awarded += 1
      rescue Exception => e
        @request_not_awarded.push([row, e])
        next
      end
    end
    flash[:error] = 'Some errors were encountered while processing the rows.' if @request_not_awarded.size > 0
  end

  def index
    @end_time   = params[:end_time] || Time.zone.now
    @start_time = params[:start_time] || 1.day.ago

    offer_ids         = Hash.new(0)
    publisher_app_ids = Hash.new(0)
    @udids            = Hash.new(0)
    @offers           = Hash.new(0)
    @publisher_apps   = Hash.new(0)
    @total            = 0

    SupportRequest.select(:where => "`updated-at` >= '#{@start_time.to_f}' AND `updated-at` < '#{@end_time.to_f}'") do |sr|
      offer_ids[sr.offer_id] += 1
      publisher_app_ids[sr.app_id] += 1
      @udids[sr.udid] += 1
      @total += 1
    end

    offer_ids.each do |k,v|
      @offers[Offer.find(k)] = v unless k.nil?
    end

    publisher_app_ids.each do |k,v|
      @publisher_apps[App.find(k)] = v unless k.nil?
    end
  end

end
