# frozen_string_literal: true

require "fileutils"

def move_file_if_exists(source_path, destination_path)
  return unless File.exist?(source_path)

  empty_directory File.dirname(destination_path)
  FileUtils.mv(source_path, destination_path)
end

files_to_relocate = {
  "app/views/layouts/application.html.erb" => "app/domains/shared/presentation/views/layouts/application.html.erb",
  "app/views/pwa/manifest.json.erb" => "app/domains/shared/presentation/views/pwa/manifest.json.erb",
  "app/views/pwa/service-worker.js" => "app/domains/shared/presentation/views/pwa/service-worker.js"
}

files_to_relocate.each do |source_path, destination_path|
  move_file_if_exists(source_path, destination_path)
end

files_to_remove = [
  "app/views/layouts/mailer.html.erb",
  "app/views/layouts/mailer.text.erb",
  "config/importmap.rb",
  "bin/importmap"
]

files_to_remove.each do |path|
  remove_file path if File.exist?(path)
end

remove_default_rails_layers("app/models")

layout_path = "app/domains/shared/presentation/views/layouts/application.html.erb"

if File.exist?(layout_path)
  gsub_file layout_path, /\n\s*<%= javascript_importmap_tags %>\n/, "\n"
end

remove_dir "app/javascript" if Dir.exist?("app/javascript")
remove_dir "app/jobs" if Dir.exist?("app/jobs")
remove_dir "app/views" if Dir.exist?("app/views")
remove_dir "vendor/javascript" if Dir.exist?("vendor/javascript")
