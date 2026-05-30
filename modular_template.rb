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

say "modular_template.rb foi mantido por compatibilidade e delega para build_ddd.rb.", :yellow
apply template_path("build_ddd.rb")
