# frozen_string_literal: true

module OpenRosa
  # DSL methods for defining form fields
  module FormDSL
    # Returns array of all fields defined in this form
    def fields
      @fields ||= []
    end

    # DSL method to add an input field
    def input(name, options = {})
      fields << Fields::Input.new(name, options)
    end

    # DSL method to add a select1 field (single select)
    def select1(name, options = {})
      fields << Fields::Select1.new(name, options)
    end

    # DSL method to add a select field (multiple select)
    def select(name, options = {})
      fields << Fields::Select.new(name, options)
    end

    # DSL method to add a boolean field
    def boolean(name, options = {})
      fields << Fields::Boolean.new(name, options)
    end

    # DSL method to add an upload field
    def upload(name, options = {})
      fields << Fields::Upload.new(name, options)
    end

    # DSL method to add a range field
    def range(name, options = {})
      fields << Fields::Range.new(name, options)
    end

    # DSL method to add a trigger field
    def trigger(name, options = {})
      fields << Fields::Trigger.new(name, options)
    end

    # DSL method to add a group field with nested fields
    def group(name, options = {}, &)
      # Create a temporary context to collect nested fields
      nested_fields = []
      if block_given?
        context = FieldContext.new(nested_fields)
        context.instance_eval(&)
      end

      fields << Fields::Group.new(name, options.merge(fields: nested_fields))
    end

    # DSL method to add a repeat field with nested fields
    def repeat(name, options = {}, &)
      # Create a temporary context to collect nested fields
      nested_fields = []
      if block_given?
        context = FieldContext.new(nested_fields)
        context.instance_eval(&)
      end

      fields << Fields::Repeat.new(name, options.merge(fields: nested_fields))
    end
  end
end
