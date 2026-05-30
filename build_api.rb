# frozen_string_literal: true

say "Iniciando o template: API Lite", :green

apply "shared/base_gems.rb"
apply "shared/i18n_setup.rb"
apply "presets/api_lite/api_gems.rb"
apply "presets/api_lite/structure.rb"
apply "presets/api_lite/foundation.rb"
apply "presets/api_lite/libs.rb"
apply "presets/api_lite/zeitwerk.rb"

after_bundle do
  apply "shared/rspec_setup.rb"
  apply "shared/post_install.rb"
end
