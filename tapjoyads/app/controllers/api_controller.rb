require 'signage/controller'

class ApiController < ApplicationController
  include Signage::Controller
  verify_signature(:secret => Rails.configuration.tapjoy_api_key)

  rescue_from Signage::Error::InvalidSignature do |exception|
    head :forbidden
  end

  private

  def get_object_type
    [nil, nil]
  end

  def lookup_object
    return unless params[:id].present? && !@object
    obj_class, is_simpledb = get_object_type
    return if obj_class.nil?
    @object = (is_simpledb ? obj_class.new(:key => params[:id]) : obj_class.new(params[:id]))
  end

  def sync_object
    lookup_object
    return unless params[:sync_changes] && @object
    merge_attributes(params[:sync_changes])

    @object.save if !@object.new_record? || params[:create_new] == true
  end

  def merge_attributes(new_attributes)
    begin
      JSON.parse(new_attributes).each do |name, value|
        @object.send("#{name.to_s}=", value)
      end
    end
  end

  def check_params(required_params)
    if required_params.any?{ |param| params[param].blank? }
      render_json_error(["Missing required params"], 422)
      return false
    end
    true
  end

  def render_json_error(errors, status = 403)
    render_formatted_response(false, nil, errors, status)
  end

  def render_formatted_response(success, data = nil, errors = [], status = 200)
    output_json = {:success => success}
    status = (status == 200 ? 500 : status) unless success
    output_json[:data] = data unless data.nil?
    output_json[:errors] = errors if errors.any?
    render(:json => output_json.to_json, :status => status)
  end

  def get_simpledb_object(obj, safe_attributes = [])
    return nil if obj.nil? || obj.new_record?
    obj_hash = { :id => obj.key, :attributes => {} }
    safe_attributes.each do |attr|
      if obj.respond_to?(attr)
        attr_value = obj.send(attr)
        obj_hash[:attributes][attr] = attr_value unless attr_value.nil?
      end
    end
    obj_hash
  end
end
