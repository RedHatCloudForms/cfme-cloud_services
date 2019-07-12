RSpec.describe Cfme::CloudServices::DataUploader do
  describe "#upload" do
    it "calls insights-client with proper parameters" do
      path = "/tmp/cfme_upload.tar.gz"
      expected_params = {:payload= => path, :content_type= => "application/vnd.redhat.topological-inventory.something+tgz"}

      expect(AwesomeSpawn).to receive(:run).with("insights-client", :params => expected_params)

      described_class.upload(path)
    end
  end
end
