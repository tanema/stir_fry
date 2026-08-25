# frozen_string_literal: true

RSpec.describe Nextrb::Server do
  subject(:server) { described_class.new }

  describe "#running?" do
    it "is false before a server has started" do
      expect(server.running?).to be false
    end

    it "is true once a running server is set" do
      server.instance_variable_set(:@running_server, Object.new)
      expect(server.running?).to be true
    end
  end

  describe "#quit!" do
    it "prefers stop! when the running server supports it" do
      running = double("running_server", stop!: nil) # rubocop:disable RSpec/VerifiedDoubles
      server.instance_variable_set(:@running_server, running)

      server.quit!

      expect(running).to have_received(:stop!)
    end

    it "falls back to stop when stop! is not available" do
      running = double("running_server", stop: nil) # rubocop:disable RSpec/VerifiedDoubles
      server.instance_variable_set(:@running_server, running)

      server.quit!

      expect(running).to have_received(:stop)
    end
  end

  describe "#chain_trap (private)" do
    it "runs the newest handler first, then chains to the previous one" do
      calls = []
      original = Signal.trap("USR1", "DEFAULT")

      begin
        server.send(:chain_trap, "USR1") { calls << :first }
        server.send(:chain_trap, "USR1") { calls << :second }
        Process.kill("USR1", Process.pid)
        sleep 0.05
      ensure
        Signal.trap("USR1", original)
      end

      expect(calls).to eq(%i[second first])
    end
  end

  describe "#run!" do
    def stub_handler
      handler = double("rackup_handler") # rubocop:disable RSpec/VerifiedDoubles
      allow(handler).to receive(:run) do |app_klass, &blk|
        blk.call(:fake_running_server)
        app_klass
      end
      allow(Rackup::Handler).to receive(:default).and_return(handler)
      handler
    end

    # run! traps real signals and registers a real at_exit hook; stubbing them here
    # (rather than avoiding subject stubs) is what keeps this a fast, isolated unit
    # test instead of one that mutates process-wide signal state.
    # rubocop:disable RSpec/SubjectStub
    before do
      allow(server).to receive(:at_exit)
      allow(server).to receive(:chain_trap)
      allow(server).to receive(:quit!)
    end

    it "runs the given app through the default rack handler" do
      handler = stub_handler

      server.run!(:my_app)

      expect(handler).to have_received(:run).with(:my_app)
    end

    it "stores the yielded server as running_server" do
      stub_handler

      server.run!(:my_app)

      expect(server.running_server).to eq(:fake_running_server)
    end

    it "calls quit! after run returns, even on success" do
      stub_handler

      server.run!(:my_app)

      expect(server).to have_received(:quit!)
    end

    it "still calls quit! if the handler raises" do
      handler = double("rackup_handler") # rubocop:disable RSpec/VerifiedDoubles
      allow(handler).to receive(:run).and_raise("boom")
      allow(Rackup::Handler).to receive(:default).and_return(handler)

      expect { server.run!(:my_app) }.to raise_error("boom")
      expect(server).to have_received(:quit!)
    end

    it "does nothing if a server is already running" do
      server.instance_variable_set(:@running_server, :already_running)
      handler = double("rackup_handler") # rubocop:disable RSpec/VerifiedDoubles
      allow(handler).to receive(:run)
      allow(Rackup::Handler).to receive(:default).and_return(handler)

      server.run!(:my_app)

      expect(handler).not_to have_received(:run)
    end
    # rubocop:enable RSpec/SubjectStub
  end
end
