require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'base64'
require 'nsisam'

$folder = File.expand_path(File.dirname(__FILE__))

describe NSICloudooo do

  before :all do
    @nsicloudooo = NSICloudooo::Client.new 'http://test:test@localhost:8886'
    @fake_cloudooo = NSICloudooo::FakeServerManager.new.start_server
  end

  after :all do
    @fake_cloudooo.stop_server
  end

  context "simple granulation" do
    it "can send a document to be granulated by a cloudooo node" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.odt')
      response.should_not be_nil
      response["key"].should == "key for document test.odt"
    end
  end

  context "granulation with conversion" do
    it "can send document in a closed format to be granulated by a cloudooo node" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.doc')
      response.should_not be_nil
      response["key"].should == "key for document test.doc"
    end
  end

  context "granulation with download" do
    it "can download documents from a link to be granulated by a cloudooo node" do
      response = @nsicloudooo.granulate(:doc_link => "http://doc_link/test.doc")
      response.should_not be_nil
      response["key"].should == "key for document test.doc"
    end
  end

  context "granualtion with callback" do
    it "can send a document to be granulated by a cloudooo node and specify a callback url" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.odt', :callback => 'http://google.com')
      response.should_not be_nil
      response["key"].should == "key for document test.odt"
      response["callback"].should == 'http://google.com'
    end

    it "can send a document to be granulated by a cloudooo node and specify the verb" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.odt', :callback => 'http://google.com', :verb => 'PUT')
      response.should_not be_nil
      response["key"].should == "key for document test.odt"
      response["callback"].should == 'http://google.com'
      response["verb"].should == 'PUT'
    end
  end

  context "verify granulation" do
    it "can verify is a granulation is done or no" do
      key = @nsicloudooo.granulate(:file => 'document', :filename => '2secs.odt')["key"]
      @nsicloudooo.done(key)["done"].should be_false
      @nsicloudooo.done(key)["done"].should be_true
    end

    it "raises an error whentrying to verify if non-existing key is done" do
      expect { @nsicloudooo.done("dont")["done"].should be_false }.to raise_error(NSICloudooo::Errors::Client::KeyNotFoundError)
    end
  end

end

