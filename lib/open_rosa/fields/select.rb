# frozen_string_literal: true

module OpenRosa
  module Fields
    # Multiple select field (checkboxes)
    # Maps to XForms <select> element
    # Values are stored as space-separated strings in submissions
    class Select < Base
      attr_reader :choices, :appearance

      def initialize(name, options = {})
        super
        @choices = options[:choices]
        @appearance = options[:appearance]

        validate!
      end

      private

      def validate!
        raise ArgumentError, "choices is required for Select field" if @choices.nil?
        raise ArgumentError, "choices must be an Array or Hash" unless @choices.is_a?(Array) || @choices.is_a?(Hash)
        raise ArgumentError, "choices cannot be empty" if @choices.empty?
      end
    end
  end
end
