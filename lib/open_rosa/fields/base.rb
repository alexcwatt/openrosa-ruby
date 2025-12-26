# frozen_string_literal: true

module OpenRosa
  module Fields
    # Base class for all form field types
    class Base
      attr_reader :name, :label, :hint, :required, :default

      def initialize(name, options = {})
        @name = name
        @label = options[:label]
        @hint = options[:hint]
        @required = options.fetch(:required, false)
        @default = options[:default]
      end
    end
  end
end
