# frozen_string_literal: true

module Exa
  module Resources
    class Websets
      class Monitors < Base
        def create(params)
          client.request(
            method: :post,
            path: monitor_path,
            body: params,
            response_model: Exa::Responses::Monitor
          )
        end

        def list(params = nil)
          client.request(
            method: :get,
            path: monitor_path,
            query: params,
            response_model: Exa::Responses::MonitorListResponse
          )
        end

        def retrieve(id)
          client.request(
            method: :get,
            path: monitor_path(id),
            response_model: Exa::Responses::Monitor
          )
        end

        def update(id, params)
          client.request(
            method: :patch,
            path: monitor_path(id),
            body: params,
            response_model: Exa::Responses::Monitor
          )
        end

        def delete(id)
          client.request(
            method: :delete,
            path: monitor_path(id),
            response_model: Exa::Responses::Monitor
          )
        end

        def runs_list(monitor_id, params = nil)
          client.request(
            method: :get,
            path: monitor_path(monitor_id, "runs"),
            query: params,
            response_model: Exa::Responses::MonitorRunListResponse
          )
        end

        def runs_get(monitor_id, run_id)
          client.request(
            method: :get,
            path: monitor_path(monitor_id, "runs", run_id),
            response_model: Exa::Responses::MonitorRun
          )
        end

        private

        def monitor_path(*parts)
          ["monitors", *parts]
        end
      end
    end
  end
end
