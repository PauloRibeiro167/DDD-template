# frozen_string_literal: true

say "Iniciando o template: DDD Modular Monolith", :green

apply "shared/base_gems.rb"
apply "shared/i18n_setup.rb"
apply "presets/ddd_modular/ddd_gems.rb"
apply "presets/ddd_modular/structure.rb"
apply "presets/ddd_modular/libs.rb"
apply "presets/ddd_modular/zeitwerk.rb"

after_bundle do
  apply "shared/rspec_setup.rb"
  apply "shared/post_install.rb"
end
