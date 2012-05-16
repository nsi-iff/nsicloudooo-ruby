require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'base64'

$folder = File.expand_path(File.dirname(__FILE__))

describe NSICloudooo do

  before :all do
    @nsicloudooo = NSICloudooo::Client.new user: 'test', password: 'test',
                                           host: 'localhost', port: '9886'
    @fake_cloudooo = NSICloudooo::FakeServerManager.new.start_server
  end

  after :all do
    @fake_cloudooo.stop_server
  end

  context "cannot connect to the server" do
    it "throws error if couldn't connec to the server" do
      nsicloudooo = NSICloudooo::Client.new user: 'test', password: 'test',
                                           host: 'localhost', port: '4000'
      expect { nsicloudooo.granulate(:file => 'document', :filename => "teste.odt") }.to \
             raise_error(NSICloudooo::Errors::Client::ConnectionRefusedError)
    end
  end

  context "simple granulation" do
    it "can send a document to be granulated by a cloudooo node" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.odt')
      response.should_not be_nil
      response["doc_key"].should == "key for document test.odt"
    end

    it "should throw error if any required parameter is missing" do
      expect { @nsicloudooo.granulate(:file => 'document') }.to raise_error(NSICloudooo::Errors::Client::MissingParametersError)
      expect { @nsicloudooo.granulate(:cloudooo_uid => 'document') }.to raise_error(NSICloudooo::Errors::Client::MissingParametersError)
      expect { @nsicloudooo.granulate(:filename => 'document') }.to raise_error(NSICloudooo::Errors::Client::MissingParametersError)
    end
  end

  context "granulation with conversion" do
    it "can send document in a closed format to be granulated by a cloudooo node" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.doc')
      response.should_not be_nil
      response["doc_key"].should == "key for document test.doc"
    end
  end

  context "granulation with download" do
    it "can download documents from a link to be granulated by a cloudooo node" do
      response = @nsicloudooo.granulate(:doc_link => "http://doc_link/test.doc")
      response.should_not be_nil
      response["doc_key"].should == "key for document test.doc"
    end
  end

  context "granualtion with callback" do
    it "can send a document to be granulated by a cloudooo node and specify a callback url" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.odt', :callback => 'http://google.com')
      response.should_not be_nil
      response["doc_key"].should == "key for document test.odt"
      response["callback"].should == 'http://google.com'
    end

    it "can send a document to be granulated by a cloudooo node and specify the verb" do
      response = @nsicloudooo.granulate(:file => 'document', :filename => 'test.odt', :callback => 'http://google.com', :verb => 'PUT')
      response.should_not be_nil
      response["doc_key"].should == "key for document test.odt"
      response["callback"].should == 'http://google.com'
      response["verb"].should == 'PUT'
    end
  end

  context "verify granulation" do
    it "can verify is a granulation is done or not" do
      key = @nsicloudooo.granulate(:file => 'document', :filename => '2secs.odt')["doc_key"]
      @nsicloudooo.done(key)["done"].should be_false
      @nsicloudooo.done(key)["done"].should be_true
      @nsicloudooo.grains_keys_for(key)["images"].should have(0).images
      @nsicloudooo.grains_keys_for(key)["files"].should have(0).files
    end

    it "can access the keys for all its grains" do
      key = @nsicloudooo.granulate(:file => 'document', :filename => '2secs.odt')["doc_key"]
      @nsicloudooo.grains_keys_for(key)["images"].should have(0).images
      @nsicloudooo.grains_keys_for(key)["files"].should have(0).files
    end

    it "raises an error whentrying to verify if non-existing key is done" do
      expect { @nsicloudooo.done("dont")["done"].should be_false }.to raise_error(NSICloudooo::Errors::Client::KeyNotFoundError)
    end
  end

  context "get configuration" do
    before do
      NSICloudooo::Client.configure do
        user     "why"
        password "chunky"
        host     "localhost"
        port     "8888"
      end
    end

    it "by configure" do
      cloudooo = NSICloudooo::Client.new
      cloudooo.instance_variable_get(:@user).should == "why"
      cloudooo.instance_variable_get(:@password).should == "chunky"
      cloudooo.instance_variable_get(:@host).should == "localhost"
      cloudooo.instance_variable_get(:@port).should == "8888"
    end

    it "by initialize parameters" do
      cloudooo = NSICloudooo::Client.new(user: 'luckystiff', password: 'bacon', host: 'why.com', port: '9999')
      cloudooo.instance_variable_get(:@user).should == "luckystiff"
      cloudooo.instance_variable_get(:@password).should == "bacon"
      cloudooo.instance_variable_get(:@host).should == "why.com"
      cloudooo.instance_variable_get(:@port).should == "9999"
    end
  end

end

