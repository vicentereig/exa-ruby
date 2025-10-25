# frozen_string_literal: true

module Exa
  module Responses
    class Monitor < T::Struct
      const :id, String
      const :status, T.nilable(String)
      const :webset_id, T.nilable(String)
      const :cadence, T.nilable(T::Hash[Symbol, T.untyped])
      const :behavior, T.nilable(T::Hash[Symbol, T.untyped])
      const :search_parameters, T.nilable(T::Hash[Symbol, T.untyped])
      const :raw, T::Hash[Symbol, T.untyped]

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          id: sym[:id],
          status: sym[:status],
          webset_id: sym[:websetId],
          cadence: sym[:cadence],
          behavior: sym[:behavior],
          search_parameters: sym[:searchParameters],
          raw: sym
        )
      end
    end

    class MonitorListResponse < T::Struct
      const :data, T::Array[Monitor]
      const :next_page_token, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { Monitor.from_hash(_1) },
          next_page_token: sym[:nextPageToken]
        )
      end
    end

    class MonitorRun < T::Struct
      const :id, String
      const :monitor_id, T.nilable(String)
      const :status, T.nilable(String)
      const :run_type, T.nilable(String)
      const :started_at, T.nilable(String)
      const :finished_at, T.nilable(String)
      const :raw, T::Hash[Symbol, T.untyped]

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          id: sym[:id],
          monitor_id: sym[:monitorId],
          status: sym[:status],
          run_type: sym[:type] || sym[:runType],
          started_at: sym[:startedAt],
          finished_at: sym[:finishedAt],
          raw: sym
        )
      end
    end

    class MonitorRunListResponse < T::Struct
      const :data, T::Array[MonitorRun]
      const :next_page_token, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { MonitorRun.from_hash(_1) },
          next_page_token: sym[:nextPageToken]
        )
      end
    end
  end
end
