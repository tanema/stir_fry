# frozen_string_literal: true

$LOAD_PATH << File.expand_path(__dir__)

require "stir_fry"

# rubocop:disable Style/OneClassPerFile
# Namespace for endpoint pages.
module Pages
  autoload :Layout, "pages/layout"
  autoload :Home,   "pages/home"
  autoload :Greet,  "pages/greet"
end

# App and route definition for the web app.
class App < StirFry::App
  get "/:name", Pages::Greet
  get "/", Pages::Home
end
# rubocop:enable Style/OneClassPerFile
