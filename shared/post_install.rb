# frozen_string_literal: true

if @include_user_setup
  if @selected_template_preset.to_s == "api"
    apply_template "shared/api_identity_setup.rb"
  else
    apply_template "shared/auth_setup.rb"
  end
end

say "Template aplicado com sucesso.", :green
say "Revise os presets em build_*.rb para criar novos flavors rapidamente.", :blue
