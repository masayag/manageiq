RSpec.describe "Instances API" do
  include Rack::Test::Methods

  def app
    Vmdb::Application
  end

  def update_raw_power_state(state, *instances)
    instances.each { |instance| instance.update_attributes!(:raw_power_state => state) }
  end

  let(:zone) { FactoryGirl.create(:zone, :name => "api_zone") }
  let(:ems) { FactoryGirl.create(:ems_openstack_infra, :zone => zone) }
  let(:host) { FactoryGirl.create(:host_openstack_infra) }
  let(:instance) { FactoryGirl.create(:vm_openstack, :ems_id => ems.id, :host => host) }
  let(:instance1) { FactoryGirl.create(:vm_openstack, :ems_id => ems.id, :host => host) }
  let(:instance2) { FactoryGirl.create(:vm_openstack, :ems_id => ems.id, :host => host) }
  let(:instance_url) { instances_url(instance.id) }
  let(:instance1_url) { instances_url(instance1.id) }
  let(:instance2_url) { instances_url(instance2.id) }
  let(:invalid_instance_url) { instances_url(999_999) }
  let(:instances_list) { [instance1_url, instance2_url] }
  before(:each) { init_api_spec_env }

  context "Instance index" do
    it "lists only the cloud instances (no infrastructure vms)" do
      api_basic_authorize
      instance = FactoryGirl.create(:vm_openstack)
      _vm = FactoryGirl.create(:vm_vmware)

      run_get(instances_url)

      expect_query_result(:instances, 1, 1)
      expect_result_resources_to_include_hrefs("resources", [instances_url(instance.id)])
      expect_request_success
    end
  end

  describe "instance terminate action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :terminate)

      run_post(invalid_instance_url, gen_request(:terminate))

      expect_resource_not_found
    end

    it "responds forbidden for an invalid instance without appropriate role" do
      api_basic_authorize

      run_post(invalid_instance_url, gen_request(:terminate))

      expect_request_forbidden
    end

    it "terminates a single valid Instance" do
      api_basic_authorize action_identifier(:instances, :terminate)

      run_post(instance_url, gen_request(:terminate))

      expect_single_action_result(
        :success => true,
        :message => /#{instance.id}.* terminating/i,
        :href    => :instance_url
      )
    end

    it "terminates multiple valid Instances" do
      api_basic_authorize collection_action_identifier(:instances, :terminate)

      run_post(instances_url, gen_request(:terminate, [{"href" => instance1_url}, {"href" => instance2_url}]))

      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results", :instances_list)
      expect_result_resources_to_match_key_data(
        "results",
        "message",
        [/#{instance1.id}.* terminating/i, /#{instance2.id}.* terminating/i]
      )
    end
  end

  describe "instance stop action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :stop)

      run_post(invalid_instance_url, gen_request(:stop))

      expect_resource_not_found
    end

    it "stopping an invalid instance without appropriate role is forbidden" do
      api_basic_authorize

      run_post(invalid_instance_url, gen_request(:stop))

      expect_request_forbidden
    end

    it "fails to stop a powered off instance" do
      api_basic_authorize action_identifier(:instances, :stop)
      update_raw_power_state("poweredOff", instance)

      run_post(instance_url, gen_request(:stop))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => :instance_url)
    end

    it "stops a valid instance" do
      api_basic_authorize action_identifier(:instances, :stop)

      run_post(instance_url, gen_request(:stop))

      expect_single_action_result(:success => true, :message => "stopping", :href => :instance_url, :task => true)
    end

    it "stops multiple valid instances" do
      api_basic_authorize action_identifier(:instances, :stop)

      run_post(instances_url, gen_request(:stop, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", :instances_list)
    end
  end

  describe "instance start action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :start)

      run_post(invalid_instance_url, gen_request(:start))

      expect_resource_not_found
    end

    it "starting an invalid instance without appropriate role is forbidden" do
      api_basic_authorize

      run_post(invalid_instance_url, gen_request(:start))

      expect_request_forbidden
    end

    it "fails to start a powered on instance" do
      api_basic_authorize action_identifier(:instances, :start)

      run_post(instance_url, gen_request(:start))

      expect_single_action_result(:success => false, :message => "is powered on", :href => :instance_url)
    end

    it "starts an instance" do
      api_basic_authorize action_identifier(:instances, :start)
      update_raw_power_state("poweredOff", instance)

      run_post(instance_url, gen_request(:start))

      expect_single_action_result(:success => true, :message => "starting", :href => :instance_url, :task => true)
    end

    it "starts multiple instances" do
      api_basic_authorize action_identifier(:instances, :start)
      update_raw_power_state("poweredOff", instance1, instance2)

      run_post(instances_url, gen_request(:start, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", :instances_list)
    end
  end

  describe "instance pause action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :pause)

      run_post(invalid_instance_url, gen_request(:pause))

      expect_resource_not_found
    end

    it "pausing an invalid instance without appropriate role is forbidden" do
      api_basic_authorize

      run_post(invalid_instance_url, gen_request(:pause))

      expect_request_forbidden
    end

    it "fails to pause a powered off instance" do
      api_basic_authorize action_identifier(:instances, :pause)
      update_raw_power_state("poweredOff", instance)

      run_post(instance_url, gen_request(:pause))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => :instance_url)
    end

    it "fails to pause a paused instance" do
      api_basic_authorize action_identifier(:instances, :pause)
      update_raw_power_state("paused", instance)

      run_post(instance_url, gen_request(:pause))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => :instance_url)
    end

    it "pauses an instance" do
      api_basic_authorize action_identifier(:instances, :pause)

      run_post(instance_url, gen_request(:pause))

      expect_single_action_result(:success => true, :message => "pausing", :href => :instance_url, :task => true)
    end

    it "pauses multiple instances" do
      api_basic_authorize action_identifier(:instances, :pause)

      run_post(instances_url, gen_request(:pause, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", :instances_list)
    end
  end
end
