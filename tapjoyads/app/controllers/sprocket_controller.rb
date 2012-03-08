class SprocketController < ApplicationController
  caches_page :show

  def show
    full_filename = params[:filename].join("/")
    extension = full_filename.split(/\./).last
    full_filename.sub! /^(.*)-.*$/, '\1'
    full_filename = "#{full_filename}.#{extension}"

    sprocket = ASSETS[full_filename]
    contents = sprocket.to_s

    if Rails.env.production?
      contents = Uglifier.new.compile(contents) if  extension == "js"
    end

    content_types = {
      "js" => "text/javascript",
      "css" => "text/css"
    }

    render :text => contents, :content_type => content_types[extension]
  end
end
