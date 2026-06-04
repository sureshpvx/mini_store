# app/helpers/form_validation_helper.rb
module FormValidationHelper
  # Renders a form input with data attributes derived from Rails validators.
  # Works for any model — no hardcoded fields.
  #
  # Usage:
  #   <%= validated_field f, :full_name %>
  #   <%= validated_field f, :email, as: :email_field %>
  #   <%= validated_field f, :phone_number, as: :telephone_field, validate_type: "india-phone" %>
  #   <%= validated_field f, :quantity, as: :number_field %>
  #   <%= validated_field f, :message, as: :text_area %>
  #
  def validated_field(form, attribute, options = {})
    field_type = options.delete(:as) || :text_field
    model      = form.object.class
    validators = model.validators_on(attribute)
    data       = options.delete(:data) || {}

    # ── Extract rules from Rails validators ──
    validators.each do |v|
      case v.class.name

        # Presence
      when "ActiveRecord::Validations::PresenceValidator"
        # Skip if validator has `if:` / `unless:` conditions we can't evaluate on the frontend
        next if conditional_validator?(v)

        options[:required] = true unless options.key?(:required)
        data[:required]    = "true"

        # Length
      when "ActiveModel::Validations::LengthValidator"
        max = v.options[:maximum] || v.options[:is]
        min = v.options[:minimum] || v.options[:is]

        data[:max_length] = max if max
        data[:min_length] = min if min

        options[:maxlength] = max if max && !options.key?(:maxlength)
        options[:minlength] = min if min && !options.key?(:minlength)

        # Format (regex)
      when "ActiveModel::Validations::FormatValidator"
        next if conditional_validator?(v)

        data[:pattern]        = v.options[:with].source
        data[:pattern_message] = v.options[:message] || "Invalid format"

        # Inclusion (e.g. country == "IN")
      when "ActiveModel::Validations::InclusionValidator"
        if v.options[:in] == %w[IN]
          data[:validate_type] = "country-in"
        end

        # Numericality
      when "ActiveModel::Validations::NumericalityValidator"
        data[:validate_type] = "numeric"

        if v.options[:only_integer]
          data[:pattern]        = "^\d+$"
          data[:pattern_message] = "Must be a whole number"
        end

        if v.options[:greater_than]
          data[:min_numeric] = v.options[:greater_than]
        end

        if v.options[:greater_than_or_equal_to]
          data[:min_numeric] = v.options[:greater_than_or_equal_to]
        end

        if v.options[:less_than]
          data[:max_numeric] = v.options[:less_than]
        end

        if v.options[:less_than_or_equal_to]
          data[:max_numeric] = v.options[:less_than_or_equal_to]
        end
      end
    end

    # ── Merge user-provided data attributes (they win) ──
    data.merge!(options.delete(:data) || {})

    # ── Stimulus wiring ──
    data[:form_validation_target] = "field"

    actions = []
    actions << "blur->form-validation#validateField"
    actions << "input->form-validation#clear"
    actions << "input->form-validation#normalize" if needs_normalize?(data)
    data[:action] = actions.join(" ")

    options[:data] = data

    # ── Dispatch to correct Rails form helper ──
    case field_type
    when :email_field     then form.email_field(attribute, options)
    when :telephone_field then form.telephone_field(attribute, options)
    when :number_field    then form.number_field(attribute, options)
    when :text_area       then form.text_area(attribute, options)
    when :password_field  then form.password_field(attribute, options)
    when :url_field       then form.url_field(attribute, options)
    when :check_box       then form.check_box(attribute, options)
    else                       form.text_field(attribute, options)
    end
  end

  private

  # Skip validators that have :if / :unless procs — we can't evaluate them in the view
  def conditional_validator?(validator)
    validator.options.key?(:if) || validator.options.key?(:unless)
  end

  # Only attach normalize handler if we have a type that needs live cleanup
  def needs_normalize?(data)
    %w[india-phone india-pin india-state country-in numeric].include?(data[:validate_type])
  end
end