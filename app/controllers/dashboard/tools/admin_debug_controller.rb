class Dashboard::Tools::AdminDebugController < Dashboard::DashboardController
  def show
    render :text => '<ul>' + LiveDebugger.new(params[:bucket]).all.map {|log| '<li>' + CGI::escapeHTML(log) + '</li>'}.join + '</ul>'
  end
end
