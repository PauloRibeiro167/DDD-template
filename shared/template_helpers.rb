# frozen_string_literal: true

# Formatting helpers for console output using ANSI escape codes.
# These helpers make template messages clearer with colors and bold text.
def ansi(code)
  "\e[#{code}m"
end

def reset
  ansi(0)
end

def bold(text)
  "#{ansi(1)}#{text}#{reset}"
end

def colorize(text, color = :default)
  colors = {
    default: 39,
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    light_gray: 37
  }

  "\e[#{colors.fetch(color, 39)}m#{text}#{reset}"
end

# Convenience wrappers that call the template `say` method when available.
def say_info(text)
  say colorize(text, :cyan)
end

def say_success(text)
  say colorize(text, :green)
end

def say_warn(text)
  say colorize(text, :yellow)
end

def say_error(text)
  say colorize(bold(text), :red)
end

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
