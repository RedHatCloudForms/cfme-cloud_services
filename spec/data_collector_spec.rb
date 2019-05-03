RSpec.describe Cfme::CloudServices::DataCollector do
  it "#process (private)" do
    zone = FactoryBot.create(:small_environment)
    ems  = zone.ext_management_systems.first

    parsed_manifest = {
      "cfme_version" => "5.11.0.0",
      "manifest"     => {
        "vmwarews" => {
          "id"    => nil,
          "name"  => nil,
          "vms"   => ["id", "name"],
          "hosts" => ["id", "name"]
        }
      }
    }

    processed = described_class.new(ems).send(:process, parsed_manifest)

    expect(processed.keys).to match_array ["id", "name", "vms", "hosts"]
    expect(processed).to include(
      "id"    => ems.id,
      "name"  => ems.name,
      "vms"   => match_array(ems.vms.select("id", "name").map(&:attributes)),
      "hosts" => match_array(ems.hosts.select("id", "name").map(&:attributes))
    )
  end
end
