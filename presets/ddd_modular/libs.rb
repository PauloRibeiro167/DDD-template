# frozen_string_literal: true

copy_template_files(
  {
    "presets/ddd_modular/files/app/assets/stylesheets/ddd_admin.css" => "app/assets/stylesheets/ddd_admin.css",
    "presets/ddd_modular/files/app/assets/stylesheets/ddd_admin/base.css" => "app/assets/stylesheets/ddd_admin/base.css",
    "presets/ddd_modular/files/app/assets/stylesheets/ddd_admin/components.css" => "app/assets/stylesheets/ddd_admin/components.css",
    "presets/ddd_modular/files/app/assets/stylesheets/ddd_admin/layouts.css" => "app/assets/stylesheets/ddd_admin/layouts.css",
    "presets/ddd_modular/files/app/assets/stylesheets/ddd_admin/tokens.css" => "app/assets/stylesheets/ddd_admin/tokens.css",
    "presets/ddd_modular/files/app/domains/shared/presentation/controllers/application_controller.rb" => "app/domains/shared/presentation/controllers/application_controller.rb",
    "presets/ddd_modular/files/lib/generators/admin_feature/admin_feature_generator.rb" => "lib/generators/admin_feature/admin_feature_generator.rb",
    "presets/ddd_modular/files/lib/generators/admin_domain/admin_domain_generator.rb" => "lib/generators/admin_domain/admin_domain_generator.rb",
    "presets/ddd_modular/files/lib/generators/admin_domain/templates/entity.rb.tt" => "lib/generators/admin_domain/templates/entity.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_domain/templates/repository.rb.tt" => "lib/generators/admin_domain/templates/repository.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_domain/templates/service_create.rb.tt" => "lib/generators/admin_domain/templates/service_create.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_domain/templates/service_update.rb.tt" => "lib/generators/admin_domain/templates/service_update.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_domain/templates/service_destroy.rb.tt" => "lib/generators/admin_domain/templates/service_destroy.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_infra/admin_infra_generator.rb" => "lib/generators/admin_infra/admin_infra_generator.rb",
    "presets/ddd_modular/files/lib/generators/admin_infra/templates/migration.rb.tt" => "lib/generators/admin_infra/templates/migration.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_infra/templates/model.rb.tt" => "lib/generators/admin_infra/templates/model.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/admin_ui_generator.rb" => "lib/generators/admin_ui/admin_ui_generator.rb",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/_form.html.erb.tt" => "lib/generators/admin_ui/templates/_form.html.erb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/controller.rb.tt" => "lib/generators/admin_ui/templates/controller.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/edit.html.erb.tt" => "lib/generators/admin_ui/templates/edit.html.erb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/form.rb.tt" => "lib/generators/admin_ui/templates/form.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/index.html.erb.tt" => "lib/generators/admin_ui/templates/index.html.erb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/new.html.erb.tt" => "lib/generators/admin_ui/templates/new.html.erb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/presenter.rb.tt" => "lib/generators/admin_ui/templates/presenter.rb.tt",
    "presets/ddd_modular/files/lib/generators/admin_ui/templates/show.html.erb.tt" => "lib/generators/admin_ui/templates/show.html.erb.tt",
    "presets/ddd_modular/files/lib/generators/bounded_context/bounded_context_generator.rb" => "lib/generators/bounded_context/bounded_context_generator.rb",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/entity.rb.tt" => "lib/generators/bounded_context/templates/entity.rb.tt",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/migration.rb.tt" => "lib/generators/bounded_context/templates/migration.rb.tt",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/model.rb.tt" => "lib/generators/bounded_context/templates/model.rb.tt",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/repository.rb.tt" => "lib/generators/bounded_context/templates/repository.rb.tt",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/service.rb.tt" => "lib/generators/bounded_context/templates/service.rb.tt"
  }
)

stylesheet_manifest_path = "app/assets/stylesheets/application.css"

unless File.exist?(stylesheet_manifest_path)
  create_file stylesheet_manifest_path, <<~CSS
    /*
     *= require_tree .
     *= require_self
     *= require ddd_admin
     */
  CSS
end

stylesheet_manifest_content = File.read(stylesheet_manifest_path)

unless stylesheet_manifest_content.include?("require ddd_admin")
  updated_manifest_content =
    if stylesheet_manifest_content.include?(" *= require_self\n")
      stylesheet_manifest_content.sub(" *= require_self\n", " *= require ddd_admin\n *= require_self\n")
    elsif stylesheet_manifest_content.include?("*/")
      stylesheet_manifest_content.sub("*/", " *= require ddd_admin\n */")
    else
      <<~CSS
        /*
         *= require_tree .
         *= require ddd_admin
         *= require_self
         */
      CSS
    end

  remove_file stylesheet_manifest_path
  create_file stylesheet_manifest_path, updated_manifest_content
end

layout_path = "app/views/layouts/application.html.erb"

if File.exist?(layout_path)
  gsub_file layout_path, "<body>", '<body class="<%= body_css_class %>">'
end
