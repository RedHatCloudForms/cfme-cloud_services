require "json"

class Cfme::CloudServices::DataCollector
  def self.collect(target)
    new(target).collect
  end

  attr_reader :target

  def initialize(target)
    @target = target
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
    #   - Should we allow collection of non-model information, such as replication,
    #     pg_* tables or filesystem level things?
    common = {
      "id"            => nil,
      "api_version"   => nil,
      "name"          => nil,
      "type"          => nil,
      "vms"           => ["id", "cpu_total_cores", "ems_ref", "name", "type", "ram_size"],
      "miq_templates" => ["id", "cpu_total_cores", "ems_ref", "name", "type", "ram_size"],
      "hosts"         => ["id", "cpu_total_cores", "ems_ref", "name", "type", "ram_size"]
    }

    {
      "cfme_version" => cfme_version,
      "manifest" => {
        "core" => {
          "Zone" => {
            "name" => nil
          }
        },
        "by_provider_type" => {
          "ManageIQ::Providers::OpenStack::CloudManager" => common.clone,
          "ManageIQ::Providers::Redhat::InfraManager" => common.clone,
          "ManageIQ::Providers::Vmware::InfraManager" => common.clone,
        }
      }
    }.to_json
  end

  def process(manifest)
    case target
    when "core"
      process_core(manifest)
    when ExtManagementSystem
      process_by_provider_type(manifest)
    else
      raise "Unknown target: #{target.inspect}"
    end
  end

  def process_core(manifest)
    core_manifest = manifest.fetch_path("manifest", "core")
    return if core_manifest.blank?

    core_manifest.each_with_object({}) do |(model, model_manifest), payload|
      payload.store_path("core", model, model.constantize.all.map { |m| extract_data(m, model_manifest) })
    end
  end

  def process_by_provider_type(manifest)
    model_manifest = manifest.fetch_path("manifest", "by_provider_type", target.class.name)
    return if model_manifest.blank?

    {"by_provider_type" => {target.class.name => extract_data(target, model_manifest)}}
  end

  def extract_data(target, model_manifest)
    return unless model_manifest

    model_manifest.each_with_object({}) do |(relation_or_column, attributes), payload|
      content = target.public_send(relation_or_column)
      content = content.select(attributes).map(&:attributes) if attributes
      payload.store_path(relation_or_column, content)
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
