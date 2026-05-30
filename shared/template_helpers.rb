# frozen_string_literal: true

# Creates a list of directories using the same DSL call everywhere.
def create_directory_tree(paths)
  paths.each do |path|
    empty_directory path
  end
end

# Creates placeholder files so empty folders survive after generation.
def create_keep_files(paths)
  paths.each do |path|
    create_file path, ""
  end
end

# Removes default Rails layers that conflict with a custom project shape.
def remove_default_rails_layers(*paths)
  paths.each do |path|
    remove_dir path if File.exist?(path)
  end
end
