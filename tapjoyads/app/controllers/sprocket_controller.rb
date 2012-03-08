class SprocketController < ApplicationController
  caches_page :show

  def show
    full_filename = params[:filename].join("/")
    extension = full_filename.split(/\./).last

    if CACHE_ASSETS
      full_filename.sub! /^(.*)-.*$/, '\1'
      full_filename = "#{full_filename}.#{extension}"
    end

    sprocket = ASSETS[full_filename]
    contents = sprocket.to_s

    content_types = {
      "js" => "application/javascript",
      "css" => "text/css"
    }

    render :text => contents, :content_type => content_types[extension]
  end
end
