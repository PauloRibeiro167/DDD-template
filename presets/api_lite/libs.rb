# frozen_string_literal: true

copy_template_files(
  {
    "presets/api_lite/files/lib/generators/api_endpoint/api_endpoint_generator.rb" => "lib/generators/api_endpoint/api_endpoint_generator.rb",
    "presets/api_lite/files/lib/generators/api_endpoint/templates/contract.rb.tt" => "lib/generators/api_endpoint/templates/contract.rb.tt",
    "presets/api_lite/files/lib/generators/api_endpoint/templates/controller.rb.tt" => "lib/generators/api_endpoint/templates/controller.rb.tt",
    "presets/api_lite/files/lib/generators/api_endpoint/templates/serializer.rb.tt" => "lib/generators/api_endpoint/templates/serializer.rb.tt",
    "presets/api_lite/files/lib/generators/api_endpoint/templates/use_case.rb.tt" => "lib/generators/api_endpoint/templates/use_case.rb.tt"
  }
)
