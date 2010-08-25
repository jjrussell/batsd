class HomeController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  def index
    now = Time.zone.now
    @start_time = now.beginning_of_hour - 23.hours
    @end_time = now
    @granularity = :hourly
    granularity_interval = 1.hour

    @stats = Appstats.new(current_partner_apps.first.id, { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity }).stats

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
