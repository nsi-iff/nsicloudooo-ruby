require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'base64'

describe NSISam do

  before :all do
    @nsicloudooo = NSICloudooo::Client.new 'http://test:test@localhost:8888'
    @keys = Array.new
    @fake_cloudooo = NSICloudooo::FakeServerManager.new.start_server
  end

  after :all do
    @fake_cloudooo.stop_server
  end

  context "granulation" do
    it "can send a video to be granulated by a cloudooo node" do
      document = Base64::encode64(File.new('26images-1table.odt', 'r').read)
      response = @nsicloudooo.granulate(document)
      response.should_not be_nil
      response.should have_key("images")
      response.should have_key("tables")
    end
  end

end

