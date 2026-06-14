require 'action_view'

module DummyHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def validated_field(form, attribute, options = {})
    field_type = options.delete(:as) || :text_field
    
    # Mock validators
    validators = []
    
    data = options.delete(:data) || {}
    
    # ── Stimulus wiring ──
    data[:form_validation_target] = "field"

    actions = []
    actions << "blur->form-validation#validateField"
    actions << "input->form-validation#clear"
    
    existing = data[:action].to_s.strip
    data[:action] = existing.empty? ? actions.join(" ") : "#{existing} #{actions.join(" ")}"

    options[:data] = data

    form.password_field(attribute, options)
  end
end

class DummyForm
  def object
    Object.new
  end
  def password_field(method, options={})
    "<input type='password' name='user[#{method}]' #{options.map { |k, v| "#{k}='#{v.is_a?(Hash) ? v.map{|dk,dv| "#{dk}:#{dv}"}.join(",") : v}'" }.join(" ")} />"
  end
end

class Test
  include DummyHelper
  
  def run
    form = DummyForm.new
    puts validated_field(form, :password, {
      as: :password_field,
      data: {
        min_length: "6",
        "password-strength-target" => "input",
        action: "focus->show blur->hide"
      }
    })
  end
end

Test.new.run
