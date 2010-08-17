class ReportingController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  def index
    if current_partner_apps.blank?
      redirect_to apps_path
    else
      redirect_to :action => 'show', :id => current_partner_apps.first.id
    end
  end

  def show
    app = App.find(params[:id], :include => [:offer])
    @offer = app.offer
    unless current_partner_apps.include?(app)
      # TODO: uncomment this after testing
      # redirect_to apps_path
    end

    now = Time.zone.now
    @start_time = now.beginning_of_hour - 23.hours
    @end_time = now
    unless params[:date].blank?
      @start_time = Time.zone.parse(params[:date]).beginning_of_day
      @start_time = now.beginning_of_hour - 23.hours if @start_time > now
      @end_time = @start_time + 24.hours
    end

    unless params[:end_date].blank?
      @end_time = Time.zone.parse(params[:end_date]).end_of_day
      @end_time = now if @end_time <= @start_time
    end

    if params[:granularity] == 'daily' || @end_time - @start_time > 7.days
      @granularity = :daily
      granularity_interval = 1.day
    else
      @granularity = :hourly
      granularity_interval = 1.hour
    end

    @stats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity }).stats

    @intervals = []
    @x_labels = []

    time = @start_time
    while time < @end_time
      @intervals << time.to_s(:pub_ampm)

      if @granularity == :daily
        @x_labels << time.strftime('%m-%d')
      else
        @x_labels << time.to_s(:time)
      end

      time += granularity_interval
    end

    if @x_labels.size > 30
      skip_every = @x_labels.size / 30
      @x_labels.size.times do |i|
        if i % (skip_every + 1) != 0
          @x_labels[i] = nil
        end
      end
    end

    @intervals << time.to_s(:pub_ampm)
  end
end
