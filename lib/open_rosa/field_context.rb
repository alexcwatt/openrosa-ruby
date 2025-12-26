# frozen_string_literal: true

module OpenRosa
  # Helper class for evaluating blocks in group/repeat DSL
  # This allows for clean nested field definitions within groups and repeats
  class FieldContext
    def initialize(fields_array)
      @fields = fields_array
    end

    def input(name, options = {})
      @fields << Fields::Input.new(name, options)
    end

    def select1(name, options = {})
      @fields << Fields::Select1.new(name, options)
    end

    def select(name, options = {})
      @fields << Fields::Select.new(name, options)
    end

    def boolean(name, options = {})
      @fields << Fields::Boolean.new(name, options)
    end

    def upload(name, options = {})
      @fields << Fields::Upload.new(name, options)
    end

    def range(name, options = {})
      @fields << Fields::Range.new(name, options)
    end

    def trigger(name, options = {})
      @fields << Fields::Trigger.new(name, options)
    end

    def group(name, options = {}, &)
      nested_fields = []
      if block_given?
        context = FieldContext.new(nested_fields)
        context.instance_eval(&)
      end

      @fields << Fields::Group.new(name, options.merge(fields: nested_fields))
    end

    def repeat(name, options = {}, &)
      nested_fields = []
      if block_given?
        context = FieldContext.new(nested_fields)
        context.instance_eval(&)
      end

      @fields << Fields::Repeat.new(name, options.merge(fields: nested_fields))
    end
  end
end
