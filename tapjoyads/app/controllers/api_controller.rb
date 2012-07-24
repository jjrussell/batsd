class ApiController < ApplicationController

  private

  def render_json_error(errors, status = 403)
    render(:json => { :success => false, :error => errors }, :status => status)
  end

  def simpledb_object_to_json(obj)
    obj_hash = { :id => obj.key }
    obj.attributes.each do |attr, attr_value|
      obj_hash[attr] = attr_value
    end
    obj_hash.to_json
  end
end
