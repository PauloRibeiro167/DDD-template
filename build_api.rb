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

def remove_gem_declaration(gem_name)
  return unless File.exist?("Gemfile")

  gsub_file "Gemfile", /^\s*gem ["']#{Regexp.escape(gem_name)}["'].*\n/, ""
end

apply_template "shared/template_options.rb"
ensure_template_options!(default_preset: "api")

say "Iniciando o template: #{selected_template_label}", :green
puts "[template] preset=api"
puts "[template] with_user_auth=#{@include_user_setup}"

apply_template "shared/base_gems.rb"
apply_template "shared/i18n_setup.rb"
apply_template "shared/template_helpers.rb"

%w[
  propshaft
  importmap-rails
  turbo-rails
  stimulus-rails
  jbuilder
  devise
  devise-jwt
  rolify
  simple_form
  kaminari
  discard
  pundit
].each do |gem_name|
  remove_gem_declaration(gem_name)
end

remove_file "config/initializers/assets.rb" if File.exist?("config/initializers/assets.rb")
remove_file "config/initializers/content_security_policy.rb" if File.exist?("config/initializers/content_security_policy.rb")

gsub_file "config/application.rb", /^(\s*)config\.api_only = .*$/, ""
inject_into_file "config/application.rb", after: "config.generators.system_tests = nil\n" do
  <<~RUBY
        config.api_only = true
  RUBY
end unless File.read("config/application.rb").include?("config.api_only = true")

%w[
  config/environments/development.rb
  config/environments/test.rb
  config/environments/production.rb
].each do |environment_file|
  next unless File.exist?(environment_file)

  gsub_file environment_file, /^\s*config\.assets\..*\n/, ""
  gsub_file environment_file, /^\s*config\.action_view\..*\n/, ""
end

apply_template "presets/api_lite/api_gems.rb"
apply_template "presets/api_lite/libs.rb"

after_bundle do
  apply_template "shared/rspec_setup.rb"
  apply_template "shared/post_install.rb"
  apply_template "presets/api_lite/finalize.rb"
end
