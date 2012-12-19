#
#   Kontagent API has a secure restful interface, supporting the following resources:
#
#     - Account
#     - User
#     - App
#
#
require 'httparty'

module Kontagent
  class Base
    include HTTParty
    debug_output STDOUT

    class << self
      def configure(opts={})
        opts = opts.with_indifferent_access

        raise "No endpoint provided" unless opts.key?(:endpoint)
        base_uri(opts.delete(:endpoint))

        raise "No username/password provided" unless opts.key?(:username) and opts.key?(:password)

        @@authentication = {}
        @@authentication[:username] = opts.delete(:username)
        @@authentication[:password] = opts.delete(:password)
      end

      #
      #   internal helpers
      #
      def auth()
        { :basic_auth => @@authentication }
      end

      def klass()
        self.name.split('::').last.downcase
      end

      #
      #   validate! considers the current operation and provided arguments.
      #   for create
      #
      def validate!(operation, args)
        unless args.has_key?(@kontagent_identifier)
          raise "Kontagent ID for this resource (#@kontagent_identifier) is a required option"
        end

        if operation == :create
          missing = (kontagent_attributes - args.keys)
          raise "Missing required Kontagent API arguments #{missing.join(', ')}" unless missing.count == 0
        elsif operation == :update
          superfluous = (args.keys - kontagent_fields)
          raise "Superfluous Kontagent API arguments #{superfluous.join(', ')}" unless superfluous.count == 0
        end
      end

      #
      #  validate and assemble the data into a hash for transmission
      #
      def body(operation,args)
        args.merge!(kontagent_constants) if operation == :create
        validate!(operation,args)

        {:body => args}
      end

      def options(operation,args={})
        auth.merge!(body(operation,args))
      end


      #
      #  DSL-oriented helpers
      #
      attr_accessor :kontagent_identifier

      def kontagent_id(id_attr)
        @kontagent_identifier = id_attr
      end

      def kontagent_attributes
        @kontagent_attributes ||= []
      end

      def optional_kontagent_attributes
        @optional_kontagent_attributes ||= []
      end

      def remote_kontagent_attributes
        @remote_kontagent_attributes ||= []
      end

      # for indicating fields only present on response
      def remote_kontagent_attr(kt_attr)
        remote_kontagent_attributes.push(kt_attr)
      end

      def kontagent_attr(kt_attr, opts={})
        if opts[:optional]
          optional_kontagent_attributes.push(kt_attr)
        else
          kontagent_attributes.push(kt_attr)
        end
      end

      # for indicating constant-valued fields
      def kontagent_constants
        @kontagent_constants ||= {}
      end

      def kontagent_const(kt_constants={})
        kontagent_constants.merge!(kt_constants)
      end

      def kontagent_fields
        [kontagent_identifier] + kontagent_attributes + optional_kontagent_attributes + kontagent_constants.keys
      end

      def kontagent_response_fields
        kontagent_fields + remote_kontagent_attributes
      end

      #
      #   crud operations
      #
      def create(args)
        post("/partner/v1/#{klass}s/",  options(:create, args))
      end

      def read()
        get("/partner/v1/#{klass}s/", auth)
      end

      def update(args)
        path = "/partner/v1/#{klass}/#{args[self.kontagent_identifier]}/"
        params = options(:update, args)
        put(path, params)
      end

      def destroy(id)
        delete("/partner/v1/#{klass}/#{id}/", auth)
      end

      #
      #   higher-level helpers
      #

      def handle_interaction(args=nil,expected_code=200)
        http_response = yield
        if http_response.code == expected_code
          http_response.parsed_response
        else
          error_message = "Invalid response from remote Kontagent host: #{http_response}"
          error_message << " (Sent arguments: #{args.inspect})" if args
          raise StandardError, error_message
        end
      end

      def all
        handle_interaction { read }
      end

      def build!(args)
        handle_interaction(args) do
          create(args)
        end
      end

      def update!(args)
        handle_interaction(args) do
          update(args)
        end
      end

      def delete!(id)
        handle_interaction(nil,204) { destroy(id) }
      end

      def find_by_id(id)
        all.select { |entity| entity["#{klass}_id"] == id  }
      end

      def find_by_attributes(attributes)
        all.select do |entity|
          attributes.all? { |k,v| entity[k.to_s] == v }
        end
      end

      def find(id_or_attr)
        if id_or_attr.is_a? String          # lookup by ID
          find_by_id(id_or_attr)
        elsif id_or_attr.is_a? Numeric
          find_by_id(id_or_attr.to_s)
        elsif id_or_attr.is_a? Hash         # lookup by params
          find_by_attributes(id_or_attr)
        else
          raise "Expecting Numeric/String ID or attributes Hash as arg to Kontagent::Base.find"
        end
      end

      def exists?(id_or_attributes)
        find(id_or_attributes).count >= 1
      end
    end
  end

  #
  #   Remote Kontagent resources
  #

  class Account < Base
    kontagent_id :account_id
    kontagent_attr :name
    kontagent_attr :subdomain
  end

  class User < Base
    kontagent_id :user_id
    kontagent_attr :username
    kontagent_attr :first_name
    kontagent_attr :last_name
    kontagent_attr :account_id
    kontagent_attr :phone,     :optional => true
    kontagent_attr :job_title, :optional => true
  end

  class Application < Base
    kontagent_id :application_id
    kontagent_attr :name
    kontagent_attr :platform_name
    kontagent_attr :account_id

    # As per spec, Application's 'platform_type' should always be "mobile".
    kontagent_const :platform_type => 'mobile'

    remote_kontagent_attr :api_key
  end
end

#
#  the remaining logic here is for bootstrapping KT provisioning API integration
#  and establishing functional mappings between our resources and theirs
#
module KontagentHelpers

  #
  #  Kontagent.id_for(resource)
  #
  #  helper to convert our ids (guids) to a KT-acceptable identifier
  #
  def self.id_for(resource)
    resource.id
  end

  #
  # helper to attempt to convert a string to valid KT subdomain
  # (remove anything non-alphanumeric, and strip first five letters/digits)
  #
  def self.to_subdomain(string)
    string.gsub(/[^0-9a-z]/i, '').downcase[0..4]
  end

  def self.mapped(resource)
    if resource.is_a? Partner
      Kontagent::Account
    elsif resource.is_a? App
      Kontagent::Application
    elsif resource.is_a? User
      Kontagent::User
    else
      raise "Kontagent mapping not available for resource type #{resource.class.name}"
    end
  end

  #
  #   assemble required Kontagent attributes for provided resource
  #
  def self.hash_for(resource)
    if resource.is_a? Partner
      partner = resource
      {
          :name        => partner.name,
          :subdomain   => to_subdomain(partner.name),
          :account_id  => id_for(partner)
      }
    elsif resource.is_a? App
      app = resource
      {
        :name           => app.name.truncate(36),
        :platform_name  => app.platform_name.try(:downcase) == 'android' ? 'android' : 'iOS',
        :account_id     => id_for(app.partner),
        :application_id => id_for(app)
      }
    elsif resource.is_a? User
      user = resource
      {
          :username    => user.email,
          :first_name  => '--',
          :last_name   => '--',
          :user_id     => id_for(user),
          :account_id  => id_for(user.current_partner)
      }
    else
      raise "Kontagent mapping not available for resource type #{resource.class.name}"
    end
  end

  #
  #   high-level KT provisioning API for our domain
  #
  def self.build!(resource)
    mapped(resource).build!(hash_for(resource))
  end

  def self.find!(resource)
    mapped(resource).find(id_for(resource))
  end

  def self.exists?(resource)
    mapped(resource).exists?(id_for(resource))
  end

  def self.update!(resource)
    mapped(resource).update!(hash_for(resource))
  end

  def self.delete!(resource)
    mapped(resource).delete!(id_for(resource))
  end

  def self.subdomain_exists?(subdomain)
    all_subdomains = Kontagent::Account.all.map { |e| e['subdomain'] }.map { |s| s.split('.').first }
    all_subdomains.include?(subdomain)
  end
end
