# frozen_string_literal: true

module OpenRosa
  module Fields
    # Repeat field for repeating sections
    # Maps to XForms <repeat> element
    # All fields within repeat can occur multiple times
    class Repeat < Base
      attr_reader :fields, :count, :appearance, :relevant

      def initialize(name, options = {})
        super
        @fields = options.fetch(:fields, [])
        @count = options[:count]
        @appearance = options[:appearance]
        @relevant = options[:relevant]
      end
    end
  end
end
