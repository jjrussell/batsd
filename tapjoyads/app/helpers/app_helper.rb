module AppHelper
  def description_size
    return 10 if @app.nil? || @app.description.nil?
    [[1 + @app.description.split(/\n/).length, 10].max, 25].min
  end
end
