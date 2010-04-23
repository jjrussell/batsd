
# A wrapper around the google charts service.
# TODO consider making generic and open sourcing
class GooglePieChart
  attr_accessor :width, :height, :color

  def initialize
    # an array of [label, value]
    @data = []
    self.width = 300
    self.height = 200
  end

  def add_data_point(label, value)
    @data << [label, value]
    @max = (@max.nil? || @max < value ? value : @max)
  end

  # render the chart to html by creating an image object and
  # placing the correct URL to the google charts api
  def render
    labels = []
    values = []
    @data.each do |label, value|
      labels << CGI::escape(label)
      values << (value > 0 ? value * 100 / @max : value).round.to_s
    end
    params = {:cht => 'p', :chs => "#{width}x#{height}", :chd => "t:#{values.join(',')}", :chl => labels.join('|') }
    params['chco'] = color if color
    
    url = "http://chart.apis.google.com/chart?#{to_query(params)}"

    alt_msg = "This pie chart is generated by Google Charts. You must be connected to the Internet to view this chart."
    html = "<img id=\"pie_chart_image\" src=\"#{url}\" alt=\"#{alt_msg}\"/>"
    return html       
  end
  
private
  # Hash#to_query is not present in all supported rails platforms, so implement
  # its equivalent here.
  def to_query(params)
    p = []
    params.each do |k,v|
      p << "#{k}=#{v}"
    end
    
    p.join "&"
  end
end
