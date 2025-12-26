# frozen_string_literal: true

module OpenRosa
  module Fields
    # Trigger field for confirmation buttons/checkboxes
    # Maps to XForms <trigger> element
    # Adds "OK" value when confirmed
    class Trigger < Base
      attr_reader :appearance

      def initialize(name, options = {})
        super
        @appearance = options[:appearance]
      end
    end
  end
end
