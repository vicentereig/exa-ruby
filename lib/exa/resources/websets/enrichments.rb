# frozen_string_literal: true

module Exa
  module Resources
    class Websets
      class Enrichments < Base
        def create(webset_id, params)
          client.request(
            method: :post,
            path: enrichments_path(webset_id),
            body: params,
            response_model: Exa::Responses::WebsetEnrichment
          )
        end

        def retrieve(webset_id, enrichment_id)
          client.request(
            method: :get,
            path: enrichments_path(webset_id, enrichment_id),
            response_model: Exa::Responses::WebsetEnrichment
          )
        end

        def update(webset_id, enrichment_id, params)
          client.request(
            method: :patch,
            path: enrichments_path(webset_id, enrichment_id),
            body: params,
            response_model: Exa::Responses::WebsetEnrichment
          )
        end

        def delete(webset_id, enrichment_id)
          client.request(
            method: :delete,
            path: enrichments_path(webset_id, enrichment_id),
            response_model: Exa::Responses::WebsetEnrichment
          )
        end

        def cancel(webset_id, enrichment_id)
          client.request(
            method: :post,
            path: enrichments_path(webset_id, enrichment_id, "cancel"),
            response_model: Exa::Responses::WebsetEnrichment
          )
        end

        private

        def enrichments_path(webset_id, *parts)
          ["v0", "websets", webset_id, "enrichments", *parts]
        end
      end
    end
  end
end
