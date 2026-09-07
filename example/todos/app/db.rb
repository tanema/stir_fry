# frozen_string_literal: true

require "yaml/store"

# DB is a wrapper around yaml store to mimic a database for persistent todos.
class DB
  @store = YAML::Store.new(File.expand_path("../data.yaml", __dir__))

  class << self
    def migrate!
      store.transaction do
        store[:todos] ||= {}
        store[:todos_id] ||= 0
      end
    end

    def all
      store.transaction { store[:todos].values }
    end

    def create(value)
      store.transaction do
        new_todo = { id: store[:todos_id], value: value, done: false }
        store[:todos][new_todo[:id]] = new_todo
        store[:todos_id] += 1
        new_todo
      end
    end

    def update(id, **args)
      store.transaction { store[:todos][id]&.merge!(args) }
    end

    def find(id)
      store.transaction(true) { store[:todos][id] }
    end

    def delete(id)
      store.transaction { store[:todos].delete(id) }
    end

    attr_reader :store
  end
end
