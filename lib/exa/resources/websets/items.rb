# frozen_string_literal: true

module Exa
  module Resources
    class Websets
      class Items < Base
        def list(webset_id, params = nil)
          client.request(
            method: :get,
            path: items_path(webset_id),
            query: params,
            response_model: Exa::Responses::WebsetItemListResponse
          )
        end

        def retrieve(webset_id, item_id)
          client.request(
            method: :get,
            path: items_path(webset_id, item_id),
            response_model: Exa::Responses::WebsetItem
          )
        end

        def delete(webset_id, item_id)
          client.request(
            method: :delete,
            path: items_path(webset_id, item_id),
            response_model: Exa::Responses::WebsetItem
          )
        end

        private

        def items_path(webset_id, *parts)
          ["v0", "websets", webset_id, "items", *parts]
        end
      end
    end
  end
end
