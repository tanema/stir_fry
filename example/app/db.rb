require 'pstore'

class DB
  @store = PStore.new("example/todos.store")

  class << self 
    def all
      store.transaction { store.keys.map {|k| store[k] } }
    end

    def count
      store.transaction { store.keys.count }
    end

    def create(value)
      id = self.count
      store.transaction do 
        store[id] = {id: id, value: value, done: false}
        store[id]
      end
    end

    def update(id, **args)
      store.transaction do 
        store[id].merge!(args) unless store[id].nil?
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

    attr_reader :store
  end
end
