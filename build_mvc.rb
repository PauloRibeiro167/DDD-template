# frozen_string_literal: true

say "Iniciando o template: Classic MVC", :green

apply "shared/base_gems.rb"
apply "shared/i18n_setup.rb"
apply "presets/classic_mvc/mvc_gems.rb"
apply "presets/classic_mvc/structure.rb"
apply "presets/classic_mvc/libs.rb"

after_bundle do
  apply "shared/rspec_setup.rb"
  apply "shared/post_install.rb"
end
