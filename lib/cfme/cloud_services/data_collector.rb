class Cfme::CloudServices::DataCollector
  def self.collect(manifest, targets)
    payload = Array(targets).map { |target| new(manifest, target).collect }
    block_given? ? yield(payload) : payload
  end

  def initialize(manifest, target)
    @manifest = manifest
    @target   = target
  end

  def collect
    payload_hash.merge(collect_target)
  end

  private

  attr_reader :manifest, :target

  def payload_hash
    {
      "cfme_version" => cfme_version,
      "schema"       => {"name" => "Cfme"},
      "manifest"     => manifest,
    }
  end

  def collect_target
    case target
    when "core"
      process_core
    when ExtManagementSystem
      process_provider
    else
      raise "Unknown target: #{target.inspect}"
    end
  end

  def process_core
    core_manifest = manifest.fetch_path("manifest", "core")
    return {} if core_manifest.blank?

    core_manifest.each_with_object({}) do |(model, model_manifest), payload|
      relation = scope_with_includes(core_manifest, model.constantize)
      content  = relation.map { |t| extract_data(t, model_manifest) }
      payload.store_path("core", model, content)
    end
  end

  def process_provider
    provider_manifest = manifest.fetch_path("manifest", target.class.name)
    return {} if provider_manifest.blank?

    object  = scope_with_includes(provider_manifest, target.class).find_by(:id => target.id)
    content = extract_data(object, provider_manifest)
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

  def cfme_version
    Vmdb::Appliance.VERSION
  end
end
