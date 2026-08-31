# frozen_string_literal: true

RSpec.describe Nextrb do
  # Nextrb is a module, so @running_server is shared singleton state across every
  # example instead of being reset by a fresh `described_class.new` like the old
  # Server class gave us. Reset it here so example order can't leak state.
  after do
    described_class.instance_variable_set(:@running_server, nil)
  end

  it "has a version number" do
    expect(Nextrb::VERSION).not_to be_nil
  end

  describe "#running?" do
    it "is false before a server has started" do
      expect(described_class.running?).to be false
    end

    it "is true once a running server is set" do
      described_class.instance_variable_set(:@running_server, Object.new)
      expect(described_class.running?).to be true
    end
  end

  describe "#quit!" do
    it "prefers stop! when the running server supports it" do
      running = double("running_server", stop!: nil) # rubocop:disable RSpec/VerifiedDoubles
      described_class.instance_variable_set(:@running_server, running)

      described_class.quit!

      expect(running).to have_received(:stop!)
    end

    it "falls back to stop when stop! is not available" do
      running = double("running_server", stop: nil) # rubocop:disable RSpec/VerifiedDoubles
      described_class.instance_variable_set(:@running_server, running)

      described_class.quit!

      expect(running).to have_received(:stop)
    end
  end

  describe "#chain_trap (private)" do
    it "runs the newest handler first, then chains to the previous one" do
      calls = []
      original = Signal.trap("USR1", "DEFAULT")

      begin
        described_class.send(:chain_trap, "USR1") { calls << :first }
        described_class.send(:chain_trap, "USR1") { calls << :second }
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
    before do
      allow(described_class).to receive(:at_exit)
      allow(described_class).to receive(:chain_trap)
      allow(described_class).to receive(:quit!)
    end

    it "runs the given app through the default rack handler" do
      handler = stub_handler

      described_class.run!(:my_app)

      expect(handler).to have_received(:run).with(:my_app, anything)
    end

    it "stores the yielded server as running_server" do
      stub_handler

      described_class.run!(:my_app)

      expect(described_class.running_server).to eq(:fake_running_server)
    end

    it "calls quit! after run returns, even on success" do
      stub_handler

      described_class.run!(:my_app)

      expect(described_class).to have_received(:quit!)
    end

    it "still calls quit! if the handler raises" do
      handler = double("rackup_handler") # rubocop:disable RSpec/VerifiedDoubles
      allow(handler).to receive(:run).and_raise("boom")
      allow(Rackup::Handler).to receive(:default).and_return(handler)

      expect { described_class.run!(:my_app) }.to raise_error("boom")
      expect(described_class).to have_received(:quit!)
    end

    it "does nothing if a server is already running" do
      described_class.instance_variable_set(:@running_server, :already_running)
      handler = double("rackup_handler") # rubocop:disable RSpec/VerifiedDoubles
      allow(handler).to receive(:run)
      allow(Rackup::Handler).to receive(:default).and_return(handler)

      described_class.run!(:my_app)

      expect(handler).not_to have_received(:run)
    end
  end
end
