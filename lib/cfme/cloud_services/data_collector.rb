require "json"
require "cfme/cloud_services/payload_builder"

class Cfme::CloudServices::DataCollector
  include Cfme::CloudServices::PayloadBuilder

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
      "id"                  => nil,
      "name"                => nil,
      "type"                => nil,
      "guid"                => nil,
      "api_version"         => nil,
      "emstype_description" => nil,
      "hostname"            => nil,
      "vms"                 => {
        "id"                   => nil,
        "name"                 => nil,
        "type"                 => nil,
        "guid"                 => nil,
        "uid_ems"              => nil,
        "archived"             => nil,
        "cpu_cores_per_socket" => nil,
        "cpu_total_cores"      => nil,
        "disks_aligned"        => nil,
        "ems_ref"              => nil,
        "has_rdm_disk"         => nil,
        "host_id"              => nil,
        "linked_clone"         => nil,
        "orphaned"             => nil,
        "power_state"          => nil,
        "ram_size_in_bytes"    => nil,
        "retired"              => nil,
        "v_datastore_path"     => nil,
        "hardware"             => {
          "id"    => nil,
          "disks" => {
            "id"           => nil,
            "device_name"  => nil,
            "device_type"  => nil,
            "disk_type"    => nil,
            "free_space"   => nil,
            "mode"         => nil,
            "size"         => nil,
            "size_on_disk" => nil,
            "partitions"   => {
              "id"                => nil,
              "name"              => nil,
              "controller"        => nil,
              "free_space"        => nil,
              "partition_type"    => nil,
              "size"              => nil,
              "start_address"     => nil,
              "used_space"        => nil,
              "virtual_disk_file" => nil,
              "volume_group"      => nil,
              "volumes"           => {
                "id"           => nil,
                "name"         => nil,
                "filesystem"   => nil,
                "free_space"   => nil,
                "size"         => nil,
                "typ"          => nil,
                "used_space"   => nil,
                "volume_group" => nil,
              }
            }
          }
        }
      }
    }

    infra_common = {
      "ems_clusters" => {
        "id"               => nil,
        "uid_ems"          => nil,
        "ems_ref"          => nil,
        "ha_enabled"       => nil,
        "drs_enabled"      => nil,
        "effective_cpu"    => nil,
        "effective_memory" => nil,
      },
      "hosts"        => {
        "id"                   => nil,
        "name"                 => nil,
        "type"                 => nil,
        "hostname"             => nil,
        "ipaddress"            => nil,
        "power_state"          => nil,
        "guid"                 => nil,
        "uid_ems"              => nil,
        "mac_address"          => nil,
        "maintenance"          => nil,
        "vmm_vendor"           => nil,
        "vmm_version"          => nil,
        "vmm_product"          => nil,
        "vmm_buildnumber"      => nil,
        "archived"             => nil,
        "cpu_cores_per_socket" => nil,
        "cpu_total_cores"      => nil,
        "ems_cluster_id"       => nil,
      },
      "storages" => {
        "id"                  => nil,
        "name"                => nil,
        "location"            => nil,
        "store_type"          => nil,
        "total_space"         => nil,
        "free_space"          => nil,
        "uncommitted"         => nil,
        "storage_domain_type" => nil,
        "host_storages"       => {
          "ems_ref" => nil,
          "host_id" => nil,
        }
      }
    }

    {
      "cfme_version" => cfme_version,
      "manifest" => {
        "core" => {
          "MiqDatabase" => {
            "id"                 => nil,
            "guid"               => nil,
            "region_number"      => nil,
            "region_description" => nil,
          },
          "Zone" => {
            "id"   => nil,
            "name" => nil
          }
        },
        "ManageIQ::Providers::OpenStack::CloudManager" => common.clone,
        "ManageIQ::Providers::Redhat::InfraManager"    => common.clone.merge(
          infra_common
        ),
        "ManageIQ::Providers::Vmware::InfraManager"    => common.clone.merge(
          "ems_extensions" => {
            "id"      => nil,
            "ems_ref" => nil,
            "key"     => nil,
            "company" => nil,
            "label"   => nil,
            "summary" => nil,
            "version" => nil
          },
          "ems_licenses"   => {
            "id"              => nil,
            "ems_ref"         => nil,
            "name"            => nil,
            "license_edition" => nil,
            "total_licenses"  => nil,
            "used_licenses"   => nil,
          },
        ).merge(
          infra_common
        ),
      }
    }.to_json
  end

  def process(manifest)
    case target
    when "core"
      process_core(manifest)
    when ExtManagementSystem
      process_provider(manifest)
    else
      raise "Unknown target: #{target.inspect}"
    end
  end

  def process_core(manifest)
    manifest = manifest.fetch_path("manifest", "core")
    return if manifest.blank?

    manifest.each_with_object({}) do |(model, model_manifest), payload|
      relation = scope_with_includes(manifest, model.constantize)
      content  = relation.map { |t| extract_data(t, model_manifest) }
      payload.store_path("core", model, content)
    end
  end

  def process_provider(manifest)
    manifest = manifest.fetch_path("manifest", target.class.name)
    return if manifest.blank?

    object  = scope_with_includes(manifest, target.class).find_by(:id => target.id)
    content = extract_data(object, manifest)
    {target.class.name => [content]}
  end

  def scope_with_includes(manifest, klass)
    klass.includes(includes_for(manifest, klass))
  end

  def includes_for(manifest, klass)
    manifest.each_with_object([]) do |(key, sub_manifest), includes|
      if klass.virtual_attribute?(key)
        includes << key
      elsif (relation = klass.reflections[key] || klass.virtual_reflection(key))
        includes << {key => includes_for(sub_manifest, relation.klass)}
      end
    end
  end

  def extract_data(target, manifest)
    return unless manifest

    manifest.each_with_object({}) do |(key, sub_manifest), payload|
      attr_or_rel = target.public_send(key)

      content =
        if attr_or_rel.kind_of?(ActiveRecord::Relation)
          attr_or_rel.map { |o| extract_data(o, sub_manifest) }
        elsif attr_or_rel.kind_of?(ActiveRecord::Base)
          extract_data(attr_or_rel, sub_manifest)
        else
          attr_or_rel
        end

      payload.store_path(key, content)
    end
  end

  INSIGHTS_CLIENT_COMMAND = "insights-client".freeze
  CONTENT_TYPE = "application/vnd.redhat.topological-inventory.something+tgz".freeze

  def post_payload(payload)
    $log.info "Collected the following payload:\n#{JSON.pretty_generate(payload)}"

    result = nil

    gzipped_tar_file_from(JSON.generate(payload)) do |packed_temporary_file_path|
      command_params = %W[--payload=#{packed_temporary_file_path} --content-type=#{CONTENT_TYPE}]
      $log.info "Trying to send inventory thru #{INSIGHTS_CLIENT_COMMAND}..."
      result = AwesomeSpawn.run(INSIGHTS_CLIENT_COMMAND, :params => command_params)

      $log.error "Successful upload by #{INSIGHTS_CLIENT_COMMAND}: #{result.output}" if result.success?
      $log.error "Error in upload by #{INSIGHTS_CLIENT_COMMAND}: #{result.output} #{result.error}" if result.failure?
    end

    result&.success?
  rescue StandardError => e
    $log.error "Error with #{INSIGHTS_CLIENT_COMMAND}: #{e}"
    false
  end

  def cfme_version
    Vmdb::Appliance.VERSION
  end
end
