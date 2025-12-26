# frozen_string_literal: true

module OpenRosa
  module Fields
    # Input field for text, numbers, dates, and other basic input types
    class Input < Base
      attr_reader :type, :constraint, :constraint_message

      VALID_TYPES = %i[
        string int decimal date time dateTime
        geopoint geotrace geoshape barcode binary intent
      ].freeze

      def initialize(name, options = {})
        super
        @type = options.fetch(:type, :string)
        @constraint = options[:constraint]
        @constraint_message = options[:constraint_message]

        validate!
      end

      private

      def validate!
        return if VALID_TYPES.include?(@type)

        raise ArgumentError, "type must be one of: #{VALID_TYPES.join(", ")}"
      end
    end
  end
end
