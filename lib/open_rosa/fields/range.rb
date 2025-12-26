# frozen_string_literal: true

module OpenRosa
  module Fields
    # Range field for numeric sliders/pickers
    # Maps to XForms <range> element
    # Data type: int or decimal
    class Range < Base
      attr_reader :start, :end, :step, :type

      VALID_TYPES = %i[int decimal].freeze

      def initialize(name, options = {})
        super
        @start = options[:start]
        @end = options[:end]
        @step = options.fetch(:step, 1)
        @type = options.fetch(:type, :int)

        validate!
      end

      private

      def validate!
        raise ArgumentError, "start is required for Range field" if @start.nil?
        raise ArgumentError, "end is required for Range field" if @end.nil?
        raise ArgumentError, "start must be less than end" if @start >= @end
        raise ArgumentError, "step must be greater than 0" if @step <= 0
        raise ArgumentError, "type must be :int or :decimal" unless VALID_TYPES.include?(@type)
      end
    end
  end
end
