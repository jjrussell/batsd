class SprocketController < ApplicationController
  caches_page :show

  def show
    full_filename = params[:filename].join("/")
    extension = full_filename.split(/\./).last

    if Sprockets::Tj.is_cached
      full_filename.sub! /^(.*)-.*$/, '\1'
      full_filename = "#{full_filename}.#{extension}"
    end

    sprocket = Sprockets::Tj.assets[full_filename]

    # skip files with dependencies in debug mode; they are handled by the helpers
    contents = Sprockets::Tj.debug ? sprocket.to_a.last.to_s : sprocket.to_s

    content_types = {
      "js" => "application/javascript",
      "css" => "text/css"
    }

    render :text => contents, :content_type => content_types[extension]
  end
end
