RSpec.describe Cfme::CloudServices::InventorySync do
  let(:zone)       { _, _, zone = EvmSpecHelper.create_guid_miq_server_zone; zone }
  let(:ems_vmware) { FactoryBot.create(:ems_vmware, :zone => zone) }
  let(:ems_rhv)    { FactoryBot.create(:ems_redhat, :zone => zone) }

  context ".sync" do
    let(:targets) { [[ems_vmware.class.name, ems_vmware.id], "core", [ems_rhv.class.name, ems_rhv.id]] }

    it "calls insights-client to upload inventory payload" do
      content_type = {:content_type= => "application/vnd.redhat.topological-inventory.something+tgz"}
      expect(AwesomeSpawn).to receive(:run).with("insights-client", :params => a_hash_including(content_type))

      described_class.sync(targets)
    end
  end

  context ".sync_queue" do
    context "with a single target" do
      let(:targets) { ems_vmware }

      it "queues the args as a class, id pair" do
        task_id = described_class.sync_queue("userid", targets)
        task = MiqTask.find(task_id)

        arg = task.miq_queue.args.first
        expect(arg.first).to eq([ems_vmware.class.name, ems_vmware.id])
      end
    end

    context "with an array of instances" do
      let(:targets) { [ems_vmware, ems_rhv] }

      it "queues the args as a class, id pair" do
        task_id = described_class.sync_queue("userid", targets)
        task = MiqTask.find(task_id)

        arg = task.miq_queue.args.first
        expect(arg.first).to eq([ems_vmware.class.name, ems_vmware.id])
        expect(arg.last).to  eq([ems_rhv.class.name, ems_rhv.id])
      end
    end

    context "with an array of class, id pairs" do
      let(:targets) { [[ems_vmware.class.name, ems_vmware.id], "core", [ems_rhv.class.name, ems_rhv.id]] }

      it "queues the args as a class, id pair" do
        task_id = described_class.sync_queue("userid", targets)
        task = MiqTask.find(task_id)

        arg = task.miq_queue.args.first
        expect(arg.first).to eq([ems_vmware.class.name, ems_vmware.id])
        expect(arg.second).to eq("core")
        expect(arg.last).to  eq([ems_rhv.class.name, ems_rhv.id])
      end
    end
  end
end
