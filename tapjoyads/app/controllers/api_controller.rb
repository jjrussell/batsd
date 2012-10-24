require 'signage/controller'

class ApiController < ApplicationController
  include Signage::Controller
  class << self; attr_accessor :is_simpledb, :object_class end

  verify_signature(:secret => Rails.configuration.tapjoy_api_key)

  rescue_from Signage::Error::InvalidSignature do |exception|
    head :forbidden
  end

  private

  def lookup_object
    return unless params[:id].present? && !@object
    return if self.class.object_class.nil?
    @object = (self.class.is_simpledb ? self.class.object_class.new(:key => params[:id]) : self.class.object_class.find_or_initialize_by_id(params[:id]))
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

  def get_object(obj, safe_attributes = [], safe_associations = {})
    return nil if obj.nil? || (obj.respond_to?(:new_record?) ? obj.new_record? : false)
    obj_hash = { :id => obj.id, :attributes => {} }
    safe_attributes.each do |attr|
      if obj.respond_to?(attr)
        attr_value = obj.send(attr)
        obj_hash[:attributes][attr] = attr_value unless attr_value.nil?
      end
    end

    obj_hash["associations"] = {}
    safe_associations.each do |association, association_safe_attributes|
      if obj.respond_to?(association)
        associated_objects = obj.send(association)
        associated_objects = [associated_objects] unless associated_objects.class == Array
        associated_objects.map! { |associated_object| get_object(associated_object, association_safe_attributes)}
        obj_hash["associations"][association.to_s] = associated_objects
      end
    end
    obj_hash
  end
end
