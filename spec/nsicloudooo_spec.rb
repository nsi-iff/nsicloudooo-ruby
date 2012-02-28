require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe NSISam do

  before :all do
    @nsisam = NSICloudooo::Client.new 'http://test:test@localhost:8888'
    @keys = Array.new
    @fake_cloudooo = NSICloudooo::FakeServerManager.new.start_server
  end

  after :all do
    @fake_cloudooo.stop_server
  end

  context "storing" do
    it "can store a value in SAM" do
      response = @nsisam.store("something")
      response.should_not be_nil
      response.should have_key("key")
      response.should have_key("checksum")
    end
  end

  context "deleting" do
    it "can delete a stored value" do
      @nsisam.store("delete this")["key"].should == 'value delete this stored'
      response = @nsisam.delete("delete this")
      response["deleted"].should be_true
    end

    it "raises error when key not found" do
      expect { @nsisam.delete("i dont exist") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

end

