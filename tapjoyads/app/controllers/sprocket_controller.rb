class SprocketController < ApplicationController
  caches_page :show

  def show
    full_filename = params[:filename]
    extension = full_filename.split(/\./).last

    full_filename.sub! /^(.*)-.*$/, '\1'
    full_filename = "#{full_filename}.#{extension}"

    sprocket = Sprockets::Tj.assets[full_filename]

    return render :text => "404 Not Found", :status => 404 unless sprocket

    # skip files with dependencies in combine mode; they are handled by sprockets
    contents = Sprockets::Tj.combine? ? sprocket.to_s : sprocket.to_a.last.to_s

    content_types = {
      "js" => "application/javascript",
      "css" => "text/css"
    }

    render :text => contents, :content_type => content_types[extension]
  end
end
