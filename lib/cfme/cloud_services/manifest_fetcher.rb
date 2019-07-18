class Cfme::CloudServices::ManifestFetcher
  def self.fetch
    manifest = JSON.parse(raw_manifest)
    block_given? ? yield(manifest) : manifest
  end

  private_class_method def self.certificate_config
    {:ssl_client_cert => OpenSSL::X509::Certificate.new(File.read("/etc/pki/consumer/cert.pem")),
     :ssl_client_key  => OpenSSL::PKey::RSA.new(File.read("/etc/pki/consumer/key.pem")),
     :verify_ssl      => OpenSSL::SSL::VERIFY_PEER}
  end

  cache_with_timeout(:raw_manifest) do
    # TODO: Modeling
    #   - Should we allow collection of non-model information, such as replication,
    #     pg_* tables or filesystem level things?

    manifest_config = ::Settings.cfme_cloud_services.manifest_configuration

    uri = URI::Generic.build(
      :scheme => manifest_config.scheme,
      :host   => manifest_config.host,
      :port   => manifest_config.port,
      :path   => File.join(manifest_config.path, Vmdb::Appliance.VERSION)
    )

    response = RestClient::Resource.new(uri.to_s, certificate_config)
    response.get
  rescue StandardError => e
    _log.error("Error with obtaining manifest with schema: #{e.message}")
    JSON.generate({})
  end
  private_class_method :raw_manifest
end
