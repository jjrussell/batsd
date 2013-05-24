class Api::Client::ReportsController < Api::ClientController
  before_filter :setup

  def sessions
    @data = transform(@appstats.graph_data[:connect_data])
  end

  private

  def stat_prefix
    group = params[:partner_id] ? 'partner' : nil
    @platform == 'all' ? group : "#{group}-#{@platform}"
  end

  def transform(graph_data)
    data = {}
    dates = graph_data[:intervals].map { |date| Time.parse(date) }
    graph_data[:main][:names].each_with_index do |name, name_index|
      data[name.downcase.gsub(' ', '_')] = { :data => graph_data[:main][:data][name_index].zip(dates) }
    end
    data
  end

  def setup
    @stat_id    = params[:partner_id] || params[:ad_id]
    @platform   = params[:platform] || 'all'
    @store_name = params[:store_name] || nil
    @start_time, @end_time, @granularity = Appstats.parse_dates(params[:start], params[:end], params[:granularity] == '1.day' ? 'daily' : 'hourly' )
    options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true, :stat_prefix => stat_prefix, :store_name => @store_name }.reject { |k,v| v == nil }
    @appstats = Appstats.new(@stat_id, options)
  end
end
