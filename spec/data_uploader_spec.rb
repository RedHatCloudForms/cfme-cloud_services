RSpec.describe Cfme::CloudServices::DataUploader do
  describe "#upload" do
    it "calls insights-client with proper parameters" do
      path = "/tmp/cfme_upload.tar.gz"
      expected_params = {:payload= => path, :content_type= => "application/vnd.redhat.topological-inventory.something+tgz"}

      expect(AwesomeSpawn).to receive(:run).with("insights-client", :params => expected_params)

      described_class.upload(path)
    end

    let(:failure_output) do
      'Uploading Insights data.' \
      'Upload attempt 1 of 1 failed! Status code: 401' \
      'All attempts to upload have failed!' \
      'Please see /var/log/insights-client/insights-client.log for additional information'
    end

    let(:failure_command_result) do
      AwesomeSpawn::CommandResult.new("", "", failure_output, 0)
    end

    it "returns false when insights-client returns failure output with exit code 0" do
      path = "/tmp/cfme_upload.tar.gz"
      expected_params = {:payload= => path, :content_type= => "application/vnd.redhat.topological-inventory.something+tgz"}

      expect(AwesomeSpawn).to receive(:run).with("insights-client", :params => expected_params).and_return(failure_command_result)

      expect(described_class.upload(path)).to be_falsey
    end
  end
end
