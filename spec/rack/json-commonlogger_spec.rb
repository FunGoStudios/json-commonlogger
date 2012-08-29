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
    Rack::Lint.new(Rack::JsonCommonLogger.new(app, @logger) {|log| {'foo' => 'bar'}})
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

    @logger.should_receive(:write).with(Yajl::Encoder.encode({'foo' => 'bar'}))
    req.get('/')
  end
end
