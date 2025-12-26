# frozen_string_literal: true

module OpenRosa
  module Fields
    # Single select field (radio buttons or dropdown)
    # Maps to XForms <select1> element
    class Select1 < Base
      attr_reader :choices, :appearance

      def initialize(name, options = {})
        super
        @choices = options[:choices]
        @appearance = options[:appearance]

        validate!
      end

      private

      def validate!
        raise ArgumentError, "choices is required for Select1 field" if @choices.nil?
        raise ArgumentError, "choices must be an Array or Hash" unless @choices.is_a?(Array) || @choices.is_a?(Hash)
        raise ArgumentError, "choices cannot be empty" if @choices.empty?
      end
    end
  end
end
