# frozen_string_literal: true

application <<~RUBY
  config.i18n.available_locales = [:"pt-BR"]
  config.i18n.default_locale = :"pt-BR"
  config.i18n.fallbacks = [:"pt-BR"]
  config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
RUBY

remove_file "config/locales/en.yml" if File.exist?("config/locales/en.yml")

initializer "locale.rb", <<~RUBY
  I18n.available_locales = [:"pt-BR"]
  I18n.default_locale = :"pt-BR"
  I18n.locale = :"pt-BR"
RUBY

empty_directory "config/locales"

create_file "config/locales/pt-BR.yml", <<~YAML
  pt-BR:
    hello: "Olá"
    errors:
      format: "%{attribute} %{message}"
      messages:
        required: "é obrigatório"
        blank: "não pode ficar em branco"
        present: "deve ficar em branco"
        taken: "já está em uso"
        invalid: "não é válido"
        not_a_number: "não é um número"
        greater_than: "deve ser maior que %{count}"
        greater_than_or_equal_to: "deve ser maior ou igual a %{count}"
        equal_to: "deve ser igual a %{count}"
        less_than: "deve ser menor que %{count}"
        less_than_or_equal_to: "deve ser menor ou igual a %{count}"
        other_than: "deve ser diferente de %{count}"
        odd: "deve ser ímpar"
        even: "deve ser par"
    activemodel:
      errors:
        messages:
          record_invalid: "A validação falhou: %{errors}"
    activerecord:
      errors:
        messages:
          record_invalid: "A validação falhou: %{errors}"
YAML

create_file "config/locales/dry_validation.pt-BR.yml", <<~YAML
  pt-BR:
    dry_validation:
      errors:
        filled?: "deve ser preenchido"
        format?: "possui formato inválido"
        int?: "deve ser um número inteiro"
        float?: "deve ser um número decimal"
        str?: "deve ser um texto"
        hash?: "deve ser um objeto"
        array?: "deve ser uma lista"
        bool?: "deve ser verdadeiro ou falso"
        date?: "deve ser uma data válida"
        time?: "deve ser um horário válido"
        size?: "deve ter tamanho %{num}"
        min_size?: "deve ter no mínimo %{num} caracteres"
        max_size?: "deve ter no máximo %{num} caracteres"
        bytesize?: "deve ter tamanho %{size}"
        gt?: "deve ser maior que %{num}"
        gteq?: "deve ser maior ou igual a %{num}"
        lt?: "deve ser menor que %{num}"
        lteq?: "deve ser menor ou igual a %{num}"
YAML
