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

apply_template "shared/template_options.rb"
ensure_template_options!(default_preset: "mvc")

say "Iniciando o template: #{selected_template_label}", :green
puts "[template] preset=mvc"
puts "[template] with_user_auth=#{@include_user_setup}"

apply_template "shared/base_gems.rb"
apply_template "shared/i18n_setup.rb"
apply_template "shared/template_helpers.rb"
apply_template "presets/classic_mvc/mvc_gems.rb"
apply_template "presets/classic_mvc/structure.rb"
apply_template "presets/classic_mvc/libs.rb"

after_bundle do
  apply_template "shared/rspec_setup.rb"
  apply_template "shared/post_install.rb"
end
