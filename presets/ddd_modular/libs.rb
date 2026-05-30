# frozen_string_literal: true

copy_template_files(
  {
    "presets/ddd_modular/files/lib/generators/bounded_context/bounded_context_generator.rb" => "lib/generators/bounded_context/bounded_context_generator.rb",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/entity.rb.tt" => "lib/generators/bounded_context/templates/entity.rb.tt",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/repository.rb.tt" => "lib/generators/bounded_context/templates/repository.rb.tt",
    "presets/ddd_modular/files/lib/generators/bounded_context/templates/service.rb.tt" => "lib/generators/bounded_context/templates/service.rb.tt"
  }
)
