module AppHelper
  def description_size
    [1 + @app.description.split(/\n/).length, 25].min
  end
end
