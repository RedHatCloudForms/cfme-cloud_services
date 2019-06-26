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
      expect(processed.keys).to eq [ems.class.name]
      processed = processed[ems.class.name]

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
      expect(processed.keys).to eq ["core"]
      processed = processed["core"]

      expect(processed.keys).to match_array ["Zone"]
      expect(processed).to include(
        "Zone" => match_array(Zone.all.select("id", "name").map(&:attributes))
      )
    end
  end
end
