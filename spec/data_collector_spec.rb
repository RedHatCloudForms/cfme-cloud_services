RSpec.describe Cfme::CloudServices::DataCollector do
  let(:parsed_manifest) do
    {
      "cfme_version" => "5.11.0.0",
      "manifest"     => {
        "core" => {
          "Zone" => {
            "id"   => nil,
            "name" => nil
          }
        },
        "ManageIQ::Providers::Vmware::InfraManager" => {
          "id"    => nil,
          "name"  => nil,
          "vms"   => {
            "id"   => nil,
            "name" => nil
          },
          "hosts" => {
            "id"   => nil,
            "name" => nil
          }
        }
      }
    }
  end

  describe "#process (private)" do
    before { FactoryBot.create(:small_environment) }

    it "with a provider target" do
      ems = ManageIQ::Providers::Vmware::InfraManager.first

      processed = described_class.new(ems).send(:process, parsed_manifest)
      expect(processed.keys).to include(ems.class.name)
      processed = processed[ems.class.name].first

      expect(processed.keys).to match_array ["id", "name", "vms", "hosts"]
      expect(processed).to include(
        "id"    => ems.id,
        "name"  => ems.name,
        "vms"   => match_array(ems.vms.select("id", "name").map(&:attributes)),
        "hosts" => match_array(ems.hosts.select("id", "name").map(&:attributes))
      )
    end

    it "with the core target" do
      processed = described_class.new("core").send(:process, parsed_manifest)
      expect(processed.keys).to include("core")
      processed = processed["core"]

      expect(processed.keys).to match_array ["Zone"]
      expect(processed).to include(
        "Zone" => match_array(Zone.all.select("id", "name").map(&:attributes))
      )
    end
  end

  describe "#collect" do
    before { FactoryBot.create(:small_environment) }
    let(:ems) { ManageIQ::Providers::Vmware::InfraManager.first }
    let(:processed) { described_class.new(ems) }

    it "calls post_payload method" do
      expect(processed).to receive(:process).and_call_original
      expect(processed).to receive(:post_payload)
      processed.send(:collect)
    end
  end

  describe "#post_payload" do
    before { FactoryBot.create(:small_environment) }
    let(:temporary_file) { Tempfile.new("file.tmp") }
    let(:command_params) { %W[--payload=#{temporary_file.path} --content-type=application/vnd.redhat.topological-inventory.something+tgz] }

    let(:payload) { {} }

    it "calls insights-client with proper parameters" do
      processed = described_class.new(nil)

      allow(processed).to receive(:gzipped_tar_file_from) { |&block| block.call(temporary_file.path) }

      expect { |probe| processed.gzipped_tar_file_from(&probe).to yield_with_args(temporary_file.path) }

      expect(AwesomeSpawn).to receive(:run).with("insights-client", :params => command_params)
      expect(processed).to receive(:gzipped_tar_file_from).with(JSON.generate(payload))

      processed.send(:post_payload, payload)
    end
  end

  describe "gzipped_tar_file_from" do
    before { FactoryBot.create(:small_environment) }
    let(:ems) { ManageIQ::Providers::Vmware::InfraManager.first }
    let(:processed) { described_class.new(ems) }
    let(:payload) { {"data" => "XXX"} }

    def unpack_tar_gz(io)
      require "rubygems/package"

      Zlib::GzipReader.wrap(io) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each { |entry| yield entry }
        end
      end
    end

    it "returns non empty result" do
      processed.gzipped_tar_file_from(JSON.generate(payload)) do |file_path|
        file = File.open(file_path, "r")
        exp = file.readlines.join("")
        io = StringIO.new(exp, "r")
        unpack_tar_gz(io) do |file_stream|
          require "json/stream"
          inventory = JSON::Stream::Parser.parse(file_stream)
          expect(inventory).to eq(payload)
        end
      end
    end
  end
end
