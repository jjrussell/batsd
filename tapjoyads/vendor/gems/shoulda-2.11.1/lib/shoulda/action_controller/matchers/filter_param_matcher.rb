module Shoulda # :nodoc:
  module ActionController # :nodoc:
    module Matchers

      # Ensures that filter_parameter_logging is set for the specified key.
      #
      # Example:
      #
      #   it { should filter_param(:password) }
      def filter_param(key)
        FilterParamMatcher.new(key)
      end

      class FilterParamMatcher # :nodoc:

        def initialize(key)
          @key = key.to_s
        end

        def matches?(controller)
          @controller = controller
          filters_params? && filters_key?
        end

        def failure_message
          "Expected #{@key} to be filtered"
        end

        def negative_failure_message
          "Did not expect #{@key} to be filtered"
        end

        def description
          "filter #{@key}"
        end

        private

        def filters_params?
          @controller.respond_to?(:filter_parameters) ||
            request.respond_to?(:filtered_parameters)
        end

        def filters_key?
          filtered_value == '[FILTERED]'
        end

        def filtered_value
          if request.respond_to?(:filtered_parameters)
            filtered_request_value
          else
            filtered_controller_value
          end
        end

        def filtered_controller_value
          filtered = @controller.send(:filter_parameters,
                                      @key.to_s => @key.to_s)
          filtered[@key.to_s]
        end

        def filtered_request_value
          request.env['action_dispatch.request.parameters'] = { @key.to_s => 'value' }
          request.filtered_parameters[@key.to_s]
        end

        def request
          @request ||= ::ActionController::TestRequest.new
        end
      end

    end
  end
end
