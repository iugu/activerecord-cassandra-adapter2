require 'uuidtools'
require 'logger'
require 'stringio'
require 'singleton'
require 'pathname'
require 'arel/visitors/cassandra'
require 'active_record'
require 'active_record/base'
require 'active_support/concern'
require 'active_support/core_ext/string'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_support/core_ext/object/blank'
require 'active_record/connection_adapters/statement_pool'

require 'cassandra-cql/1.1'

module ActiveRecord

  class Base

    # Initialize a Connection based on database.yml parameters
    def self.cassandra_connection(config)
      connection_options = config.symbolize_keys
      connection_options.reverse_merge! :keyspace => 'system', :seed_nodes => ['127.0.0.1:9160']

      ConnectionAdapters::CassandraAdapter.new(nil, logger, connection_options, config)
    end
  end

  module ConnectionAdapters
    class CassandraColumn < Column

      private
    end

    class CassandraAdapter < AbstractAdapter
      class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition

        class StatementPool < ConnectionAdapters::StatementPool
          def initialize(connection, max)
            super
            @cache = Hash.new { |h,pid| h[pid] = {} }
          end

          def each(&block); cache.each(&block); end
          def key?(key); cache.key?(key); end
          def [](key); cache[key]; end
          def length; cache.length; end

          def []=(sql, key)
            while @max <= cache.size
              dealloc(cache.shift.last[:stmt])
            end
            cache[sql] = key
          end

          def clear
            cache.values.each do |hash|
              dealloc hash[:stmt]
            end
            cache.clear
          end

          private
          def cache
            @cache[$$]
          end

          def dealloc(stmt)
            stmt.close unless stmt.closed?
          end
        end
      end

      def initialize(connection, logger, connection_options, config)
        super( connection, logger )

        @connection_options, @config = connection_options, config
        @keyspace = @connection_options[:keyspace]

        # TODO: Change to our own Visitor / Query Builder - Using a Default To SQL here
        @visitor = Arel::Visitors::ToSql.new self if defined?(Arel::Visitors::ToSql)
      end

      # Usecode
      
      def columns(table_name, name = nil)

        puts table_name

        columnfamilies = {}
        @connection.execute("SELECT * from system.schema_columnfamilies").fetch do |row|
          cinfo = row.to_hash
          if cinfo['keyspace'] == @keyspace
            columnfamilies[ cinfo['columnfamily']] = {
              :family => cinfo['columnfamily'],
              :key => cinfo['key_alias'],
              :key_validator => cinfo['key_validator'],
              :default_validator => cinfo['default_validator'],
              :comparator => cinfo['comparator']
            }
          end
        end

        cfc = []
        if columnfamilies[ table_name ]
          cfc << {
            :name => columnfamilies[ table_name ][:key],
            :type => columnfamilies[ table_name ][:key_validator],
            :primary => true
          }
        end

        @connection.execute("SELECT * from system.schema_columns").fetch do |row|
          cinfo = row.to_hash
          if (cinfo['columnfamily'] == table_name) and (cinfo['keyspace'] == @keyspace)
            cfc << {
              :name => cinfo['column'],
              :type => cinfo['validator'],
              :avaiable_index => cinfo['index_name']
            }
          end
        end
        
        puts cfc.inspect

        # puts y(columnfamilies)
        # puts y(columnfamily_columns)
        # select * from system.schema_columns
        []
      end

      # Connection Management
      def active?
        return false unless @connection
        @connection.active?
      end

      def reconnect!
        disconnect!
        connect
      end
      alias :reset! :disconnect!

      def disconnect!
        unless @connection.nil?
          @connection.disconnect!
          @connection = nil
        end
      end

      def connect
        @connection = CassandraCQL::Database.new( @connection_options[:seed_nodes], { :keyspace => @connection_options[:keyspace] } )
      end

      # Specific 

      # Adapter Features
      
      def supports_migrations?
        true
      end
      
      def supports_primary_key?
        true
      end
      
      def supports_count_distinct?
        false
      end
      
      def supports_ddl_transactions?
        false
      end
      
      def supports_bulk_alter?
        false
      end
      
      def supports_savepoints?
        false
      end
      
      def supports_index_sort_order?
        false
      end
      
      def supports_explain?
        false
      end

      # Adapter Information

      def adapter_name
        'Cassandra'
      end

      def version
        self.class::VERSION
      end

      def cql_version
        CassandraCQL.CASSANDRA_VERSION
      end
    end
  end
end
