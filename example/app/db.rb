# frozen_string_literal: true

require "pstore"

# DB is a wrapper around pstore to mimic a database for persistent todos.
class DB
  @store = PStore.new("example/todos.store")

  class << self
    def all
      store.transaction { store.keys.map { |k| store[k] } }
    end

    def count
      store.transaction { store.keys.count }
    end

    def create(value)
      id = next_id + 1
      store.transaction do
        store[id] = { id: id, value: value, done: false }
        store[id]
      end
    end

    def update(id, **args)
      store.transaction do
        store[id]&.merge!(args)
        store[id]
      end
    end

    def find(id)
      store.transaction(true) { store[id] }
    end

    def on(id)
      store.transaction(true) { store[id] }
    end

    def delete(id)
      store.transaction { store.delete(id) }
    end

    private

    def next_id
      store.transaction { store.keys.map(&:to_i).max + 1 }
    end

    attr_reader :store
  end
end
