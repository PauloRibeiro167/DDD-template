# frozen_string_literal: true

require "open-uri"

def template_root
  @template_root ||= begin
    current_template = __FILE__.to_s

    if current_template.match?(%r{\Ahttps?://})
      current_template.sub(%r{/[^/]+$}, "")
    else
      File.expand_path("..", current_template)
    end
  end
end

def template_path(relative_path)
  if template_root.match?(%r{\Ahttps?://})
    "#{template_root}/#{relative_path}"
  else
    File.expand_path(relative_path, template_root)
  end
end

def apply_template(relative_path)
  apply template_path(relative_path)
end

def copy_template_file(source_relative_path, destination_path)
  source = template_path(source_relative_path)
  content = source.match?(%r{\Ahttps?://}) ? URI.open(source, &:read) : File.binread(source)

  create_file destination_path, content, force: true
end

def copy_template_files(file_mappings)
  file_mappings.each do |source_relative_path, destination_path|
    copy_template_file(source_relative_path, destination_path)
  end
end

say "Iniciando o template: DDD Modular Monolith", :green

apply_template "shared/base_gems.rb"
apply_template "shared/i18n_setup.rb"
apply_template "shared/template_helpers.rb"
apply_template "presets/ddd_modular/ddd_gems.rb"
apply_template "presets/ddd_modular/structure.rb"
apply_template "presets/ddd_modular/libs.rb"
apply_template "presets/ddd_modular/zeitwerk.rb"

after_bundle do
  apply_template "shared/rspec_setup.rb"
  apply_template "shared/post_install.rb"
end
