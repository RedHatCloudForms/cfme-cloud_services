class Cfme::CloudServices::ManifestFetcher
  def self.fetch
    manifest = JSON.parse(raw_manifest)
    block_given? ? yield(manifest) : manifest
  end

  private_class_method def self.raw_manifest
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
      "cfme_version" => Vmdb::Appliance.VERSION,
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
end
