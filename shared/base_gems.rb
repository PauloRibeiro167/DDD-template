# frozen_string_literal: true

# Helper: checa se o Gemfile do projeto já declara uma gem
def gem_declared_in_project?(name)
	app_gemfile = File.join(Dir.pwd, 'Gemfile')
	return false unless File.exist?(app_gemfile)
	content = File.read(app_gemfile)
	content.match?(/gem ["']#{Regexp.escape(name)}["']/)
end

### Produção (gems essenciais em runtime)
gem "puma", "~> 8.0", ">= 8.0.2" unless gem_declared_in_project?("puma")
gem "pg", "~> 1.6", ">= 1.6.3" unless gem_declared_in_project?("pg")
gem "bootsnap", "~> 1.24", ">= 1.24.5" unless gem_declared_in_project?("bootsnap")
gem "redis", "~> 5.4", ">= 5.4.1" unless gem_declared_in_project?("redis")
gem "sidekiq", "~> 8.1", ">= 8.1.6" unless gem_declared_in_project?("sidekiq")
gem "rack-attack", "~> 6.8", ">= 6.8.0" unless gem_declared_in_project?("rack-attack")

### Autenticação, autorização e UI (produção)
gem "devise", "~> 5.0", ">= 5.0.4" unless gem_declared_in_project?("devise")
gem "devise-jwt", "~> 0.12", ">= 0.12.1" unless gem_declared_in_project?("devise-jwt")
gem "pundit", "~> 2.5", ">= 2.5.2" unless gem_declared_in_project?("pundit")
gem "rolify", "~> 6.0", ">= 6.0.1" unless gem_declared_in_project?("rolify")
gem "kaminari", "~> 1.2", ">= 1.2.2" unless gem_declared_in_project?("kaminari")
gem "simple_form", "~> 5.4", ">= 5.4.1" unless gem_declared_in_project?("simple_form")
gem "discard", "~> 2.0", ">= 2.0.0" unless gem_declared_in_project?("discard")
gem "rails-i18n", "~> 8.1", ">= 8.1.0" unless gem_declared_in_project?("rails-i18n")

### Desenvolvimento e Testes
gem "pry-rails", "~> 0.3.11", group: %i[development test] unless gem_declared_in_project?("pry-rails")
gem "pry-byebug", "~> 3.12", group: %i[development test] unless gem_declared_in_project?("pry-byebug")
gem "pry-doc", "~> 1.7", group: %i[development test] unless gem_declared_in_project?("pry-doc")
gem "byebug", "~> 13.0", group: :development unless gem_declared_in_project?("byebug")

### Testes
gem "rspec-rails", "~> 8.0", ">= 8.0.4", group: %i[development test] unless gem_declared_in_project?("rspec-rails")
gem "factory_bot_rails", "~> 6.5", ">= 6.5.1", group: %i[development test] unless gem_declared_in_project?("factory_bot_rails")
gem "faker", "~> 3.8", ">= 3.8.0", group: %i[development test] unless gem_declared_in_project?("faker")
gem "simplecov", "~> 0.22.0", require: false, group: :test unless gem_declared_in_project?("simplecov")

### Ferramentas de desenvolvimento/qualidade
gem "bullet", "~> 8.1", ">= 8.1.2", group: :development unless gem_declared_in_project?("bullet")
gem "dotenv-rails", "~> 3.2", ">= 3.2.0", group: %i[development test] unless gem_declared_in_project?("dotenv-rails")
gem "rubocop", "~> 1.86", ">= 1.86.2", require: false, group: :development unless gem_declared_in_project?("rubocop")
gem "brakeman", "~> 8.0", ">= 8.0.4", require: false, group: :development unless gem_declared_in_project?("brakeman")

### Observações
# - Versões usadas são as versões estáveis mais recentes consultadas no RubyGems
#   (maio/2026) — revisar periodicamente antes de atualizar um projeto.