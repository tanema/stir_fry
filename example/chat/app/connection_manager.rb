# frozen_string_literal: true

# Connection manager maintains a set of connections to chat members. It will broadcast
# to all connections and remove the connections when they disconnect.
class ConnectionManager
  @connections = Set.new
  @message_queue = Thread::Queue.new

  class << self
    attr_accessor :connections, :message_queue

    def listen_for_messages!
      Thread.new do
        loop do
          message = "data: #{message_queue.pop}\n\n"
          connections.each { |conn| send_message(conn, message) }
        end
      end
    end

    # /stream endpoint
    def get(request:, response:, **)
      user = request.session[:user]
      return response.unauthorized("Login required") if user.nil?

      response.stream do |conn|
        connections.add(conn)
        message_queue << "#{user} connected."
        conn.write("heartbeat:\n")
      end
    end

    def queue_message(msg)
      message_queue << msg
    end

    private

    def send_message(conn, message)
      conn.write(message)
    rescue Errno::EPIPE
      conn.close
      connections.delete(conn)
    end
  end
end
