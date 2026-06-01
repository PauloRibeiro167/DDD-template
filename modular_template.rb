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

apply template_path("shared/template_options.rb")
apply template_path("shared/template_helpers.rb")

selected_preset = ask_template_preset(default: "ddd")
ask_include_user_setup

say_info "Template selecionado: #{bold(selected_template_label)}"
say_warn "Autenticação de usuários: #{@include_user_setup ? colorize('sim', :green) : colorize('não', :red)}"
puts "[template] selected_preset=#{selected_preset}"
puts "[template] include_user_auth=#{@include_user_setup}"

build_script =
  case selected_preset
  when "api"
    "build_api.rb"
  when "mvc"
    "build_mvc.rb"
  else
    "build_ddd.rb"
  end

apply template_path(build_script)
