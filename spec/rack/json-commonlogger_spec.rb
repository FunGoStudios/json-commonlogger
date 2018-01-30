require 'spec_helper'
require 'rack/lint'
require 'rack/mock'

describe Rack::JsonCommonLogger do
  before do
    @logger = Object.new
    @logger.stub(:write).and_return(true)
  end

  def json_commonlogger(app)
    Rack::Lint.new Rack::JsonCommonLogger.new(app, @logger)
  end

  def json_custom_commonlogger(app)
    Rack::Lint.new(Rack::JsonCommonLogger.new(app, @logger))
  end

  it 'writes to the log' do
    req = Rack::MockRequest.new(
      json_commonlogger(
        lambda{|env| [200, {'Content-Type' => 'text/plain'}, ['Hello Rack::JsonCommonLogger']] }
    ))

    @logger.should_receive(:write)
    req.get('/')
  end

  it 'writes a custom log' do
    req = Rack::MockRequest.new(
      json_custom_commonlogger(
        lambda{|env| [200, {'Content-Type' => 'text/plain'}, ['Hello Rack::JsonCommonLogger']] }
    ))

    @logger.should_receive(:write) do |log|
      log_decoded = Yajl::Parser.new.parse(log)
      log_decoded['method'].should eq('GET')
      log_decoded['status'].should eq("200")
      log_decoded['path'].should eq('/')
      log_decoded['length'].should eq("-")
      log_decoded['body_data'].should eq('')
    end
    req.get('/')
  end

  it 'writes a custom log with post data' do
    req = Rack::MockRequest.new(
      json_custom_commonlogger(
        lambda{|env| [200, {'Content-Type' => 'text/plain'}, ['Hello Rack::JsonCommonLogger']] }
      ))

    @logger.should_receive(:write) do |log|
      log_decoded = Yajl::Parser.new.parse(log)
      log_decoded['method'].should eq('POST')
      log_decoded['status'].should eq("200")
      log_decoded['path'].should eq('/')
      log_decoded['length'].should eq("-")
      log_decoded['body_data'].should eq('message=hello')
    end
    req.post('/', :params => {:message => 'hello'})
  end
end
