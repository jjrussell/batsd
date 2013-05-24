class HighchartsGraph
  def self.generate_graph(graph_data, title, xaxis_title, yaxis_title, data_type, legend=true, tooltip=true)
    LazyHighCharts::HighChart.new('column') do |f|
      graph_data.each do |data|
        f.series(:data => data, :type => data_type, :show_in_legend => legend)
      end
      f.title({:text => title})
      f.options[:tooltip] = {:enabled => false}
      f.options[:xAxis] = { :title => { :text => xaxis_title }}
      f.options[:yAxis] = { :title => { :text => yaxis_title }}
    end
  end

  def self.example_conversion_rates_graph
    LazyHighCharts::HighChart.new('column') do |f|
      f.series(:data => [[0, 10], [1, 10]], :type => 'area', :show_in_legend => false)
      f.series(:data => [[1, 30], [2, 30]], :type => 'area', :show_in_legend => false)
      f.series(:data => [[2, 70], [3, 70]], :type => 'area', :show_in_legend => false)
      f.series(:data => [[3, 140], [4, 140]], :type => 'area', :show_in_legend => false)
      f.series(:data => [[4, 350], [8, 350]], :type => 'area', :show_in_legend => false)
      f.options[:xAxis] = { :title => { :text => I18n.t('text.conversion_rate.xaxis') }}
      f.options[:yAxis] = { :title => { :text => I18n.t('text.conversion_rate.yaxis') }}
      f.title({:text => I18n.t('text.conversion_rate.graph_title')})
      f.options[:tooltip] = {:enabled => false}
    end
  end
end
