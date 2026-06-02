# frozen_string_literal: true

require "io/console"

unless defined?(TEMPLATE_PRESET_LABELS)
  TEMPLATE_PRESET_LABELS = {
    "api" => "API simples",
    "ddd" => "DDD Modular Monolito",
    "mvc" => "MVC classico"
  }.freeze
end

def normalize_yes_no(value)
  value.to_s.strip.downcase
end

def ansi(code)
  "\e[#{code}m"
end

def reset_ansi
  ansi(0)
end

def bold(text)
  "#{ansi(1)}#{text}#{reset_ansi}"
end

def colorize(text, color = :default)
  colors = {
    default: 39,
    green: 32,
    yellow: 33,
    cyan: 36,
    white: 37,
    black: 30
  }

  "\e[#{colors.fetch(color, 39)}m#{text}#{reset_ansi}"
end

def terminal_width
  IO.console.winsize[1]
rescue StandardError
  80
end

def truncate_text(text, max_length)
  return text if text.length <= max_length
  return text[0, max_length] if max_length <= 1

  "#{text[0, max_length - 1]}…"
end

def strip_ansi(text)
  text.gsub(/\e\[[\d;]*m/, "")
end

def box_width_for_menu(prompt, options)
  widest_label = options.map { |_value, label| label.length }.max || 0
  widest_help = "↑/↓ mover  Enter confirmar  Esc cancelar".length
  content_width = [prompt.length, widest_label + 2, widest_help].max

  [content_width + 2, terminal_width - 6].min.clamp(28, 52)
end

def box_margin(width)
  [(terminal_width - width) / 2, 0].max
end

def indent_text(text, margin)
  "#{' ' * margin}#{text}"
end

def centered_text(content, width)
  visible = truncate_text(strip_ansi(content), width)
  visible.center(width)
end

def left_pad_for(text)
  len = strip_ansi(text).length
  pad = ((terminal_width - len) / 2.0).floor
  pad < 0 ? 0 : pad
end

def box_line(content, width)
  inner_width = [width - 2, 1].max
  visible = truncate_text(strip_ansi(content), inner_width).ljust(inner_width)
  visible
end

def box_border(width)
  "-" * width
end

def highlighted_box_line(content, width)
  inner_width = [width - 2, 1].max
  visible = truncate_text(strip_ansi(content), inner_width).ljust(inner_width)
  colorize(bold(visible), :cyan)
end

def plain_box_line(content, width)
  inner_width = [width - 2, 1].max
  visible = truncate_text(strip_ansi(content), inner_width).ljust(inner_width)
  visible
end

def clear_screen
  print "\e[H\e[2J\e[3J"
end

def clear_screen_lines(lines)
  return if lines <= 0

  lines.times do
    print "\e[1A\e[2K"
  end
end

def interactive_select(prompt, options, default_index: 0)
  return options[default_index]&.first if options.empty?

  # Prefer tty-prompt when available (robust handling of terminal quirks)
  begin
    require "tty-prompt"
    if STDIN.tty? && STDOUT.tty?
      tty = TTY::Prompt.new
      choices = {}
      options.each do |value, label|
        choices[strip_ansi(label)] = value
      end
      selection = tty.select(strip_ansi(prompt), choices, per_page: [options.length, 10].max)
      return selection
    end
  rescue LoadError
    # tty-prompt not installed — fall back to built-in selector
  end

  return fallback_select(prompt, options, default_index: default_index) unless STDIN.tty? && STDOUT.tty?

  index = [[default_index, 0].max, options.length - 1].min
  max_label_width = options.map { |_value, label| label.length }.max || 0
  help_text = "↑/↓ mover | Enter confirmar | Esc cancelar"
  menu_width = [prompt.length, max_label_width + 4, help_text.length].max
  menu_width = [menu_width, terminal_width - 6].min.clamp(24, 60)

  # Build visible lines and compute a single left column so the block aligns vertically
  visible_options = options.map { |_v, label| truncate_text(strip_ansi(format("%s %s", " ", label)), menu_width) }
  max_line_len = [visible_options.map(&:length).max || 0, prompt.length, help_text.length].max
  left_col = [(terminal_width - max_line_len) / 2, 0].max

  show_menu = lambda do
    clear_screen

    # Imprime o prompt centralizado em relação ao bloco
    prompt_pad = left_col + ((max_line_len - strip_ansi(prompt).length) / 2.0).floor
    puts "#{' ' * prompt_pad}#{truncate_text(strip_ansi(prompt), menu_width)}"
    puts ""

    options.each_with_index do |(_value, label), option_index|
      marker = option_index == index ? "▶" : " "
      line = format("%s %s", marker, label)
      visible_line = truncate_text(strip_ansi(line), max_line_len)

      if option_index == index
        # use invert helper to highlight the whole visible line (reverse video)
        puts "#{' ' * left_col}#{invert(visible_line.ljust(max_line_len))}"
      else
        puts "#{' ' * left_col}#{visible_line.ljust(max_line_len)}"
      end
    end

    puts ""
    help_pad = left_col + ((max_line_len - help_text.length) / 2.0).floor
    puts "#{' ' * help_pad}#{help_text}"
  end

  STDIN.raw do
    loop do
      show_menu.call

      key = STDIN.getch

      case key
      when "\r", "\n"
        clear_screen
        return options[index].first
      when "\u0003"
        clear_screen
        raise Interrupt, "Seleção cancelada"
      when "\e"
        sequence = key + (STDIN.read_nonblock(2, exception: false) || "")

        case sequence
        when "\e[A"
          index = (index - 1) % options.length
        when "\e[B"
          index = (index + 1) % options.length
        else
          clear_screen
          raise Interrupt, "Seleção cancelada"
        end
      end
    end
  end
rescue Interrupt
  nil
end

def fallback_select(prompt, options, default_index: 0)
  values = options.map(&:first)
  labels = options.map { |value, label| "#{value} (#{label})" }.join(", ")
  answer = ask("#{prompt} #{labels} (padrão: #{values[default_index]})")&.strip&.downcase

  return values[default_index] if answer.nil? || answer.empty?

  matched_label = options.find { |value, label| value == answer || label.downcase == answer }
  matched_label&.first || values[default_index]
end

def prompt_with_default(prompt, default = nil)
  if default.nil?
    ask(prompt)
  else
    ask("#{prompt} (padrão: #{default})")
  end
end

def ask_template_preset(default: "ddd")
  return @selected_template_preset if defined?(@selected_template_preset) && @selected_template_preset

  options = TEMPLATE_PRESET_LABELS.to_a
  default_index = options.index { |value, _label| value == default } || 0
  selected = interactive_select("Qual tipo de template deseja gerar?", options, default_index: default_index)

  @selected_template_preset = selected || default
end

def ask_include_user_setup(default: true)
  return @include_user_setup unless @include_user_setup.nil?

  options = [[true, "Sim"], [false, "Não"]]
  default_index = default ? 0 : 1
  selected = interactive_select("Gerar com user/autenticacao?", options, default_index: default_index)

  @include_user_setup = selected.nil? ? default : selected
end

def ensure_template_options!(default_preset:)
  @selected_template_preset ||= default_preset
  ask_include_user_setup
end

def selected_template_label
  TEMPLATE_PRESET_LABELS.fetch(@selected_template_preset) { @selected_template_preset.to_s.capitalize }
end
