require 'rubygems'

$: << File.join(File.dirname(__FILE__), "..", "lib")

require 'activerecord-cassandra-adapter2'
require 'active_record/connection_adapters/cassandra_adapter'

require 'active_record'
require 'active_record/version'

if ActiveRecord::VERSION::MAJOR > 2
  require 'rspec' # rspec 2
else
  require 'spec' # rspec 1
end

ActiveRecord::Base.establish_connection(
  :adapter  =>  'cassandra',
  :keyspace => 'ar_adapter'
)

class TestTable < ActiveRecord::Base
end

a = TestTable.new

describe "ActiveRecord Testing" do
  it "should return true" do
    true.should be_true
  end
end
