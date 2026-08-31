# frozen_string_literal: true

# The domain of todo management.
module Todos
  autoload :Todo, File.expand_path("todos/todo", __dir__)
  autoload :List, File.expand_path("todos/list", __dir__)
end
