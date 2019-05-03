require "json"

class Cfme::CloudServices::DataCollector
  def self.collect(provider)
    new(provider).collect
  end

  attr_reader :provider

  def initialize(provider)
    @provider = provider
  end

  def collect
    post_payload(process(fetch_manifest))
  end

  private

  def fetch_manifest
    JSON.parse(raw_manifest)
  end

  def raw_manifest
    # TODO: Download the manifest from the cloud for this CF version...for now just hardcode
    #
    # TODO: Modeling
    #   - Should we allow collection of non-provider information, such as the
    #     miq_servers, or even the CF version?
    #   - Should we use the reporting format, and use the reporting engine
    #     for collection?  This might allow deeper relationships.
    common = {
      "id"            => nil,
      "api_version"   => nil,
      "name"          => nil,
      "type"          => nil,
      "vms"           => ["id", "ems_ref", "name", "type"],
      "miq_templates" => ["id", "ems_ref", "name", "type"],
      "hosts"         => ["id", "ems_ref", "name", "type"]
    }

    {
      "cfme_version" => cfme_version,
      "manifest"     => {
        "openstack" => common.clone,
        "rhevm"     => common.clone,
        "vmwarews"  => common.clone,
      }
    }.to_json
  end

  def process(manifest)
    provider_manifest = manifest.fetch_path("manifest", provider.emstype)
    return {} if provider_manifest.blank?

    provider_manifest.each_with_object({}) do |(relation, attributes), payload|
      content = provider.public_send(relation)
      content = content.select(attributes).map { |o| o.attributes } if attributes
      payload.store_path(relation, content)
    end
  end

  def post_payload(payload)
    # TODO: Post the payload to the cloud...for now just write to log and STDOUT
    msg = "Collected the following payload:\n#{JSON.pretty_generate(payload)}"
    $log.info msg
    puts msg
  end

  def cfme_version
    "5.11.0.0" # TODO: Dynamically retrieve this
  end
end
