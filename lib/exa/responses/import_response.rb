# frozen_string_literal: true

module Exa
  module Responses
    module ImportAttributes
      module_function

      def apply(base)
        base.const :id, String
        base.const :object, T.nilable(String)
        base.const :status, T.nilable(String)
        base.const :format, T.nilable(String)
        base.const :entity, T.nilable(T.untyped)
        base.const :title, T.nilable(String)
        base.const :count, T.nilable(Integer)
        base.const :metadata, T.nilable(T::Hash[String, String])
        base.const :failed_reason, T.nilable(String)
        base.const :failed_at, T.nilable(String)
        base.const :failed_message, T.nilable(String)
        base.const :created_at, T.nilable(String)
        base.const :updated_at, T.nilable(String)
      end
    end

    module ImportResponseHelpers
      module_function

      def build_common(sym)
        entity = sym[:entity]
        entity = Helpers.symbolize_keys(entity) if entity.is_a?(Hash)
        {
          id: sym[:id],
          object: sym[:object],
          status: sym[:status],
          format: sym[:format],
          entity: entity,
          title: sym[:title],
          count: sym[:count]&.to_i,
          metadata: Helpers.stringify_string_hash(sym[:metadata]),
          failed_reason: sym[:failedReason],
          failed_at: sym[:failedAt],
          failed_message: sym[:failedMessage],
          created_at: sym[:createdAt],
          updated_at: sym[:updatedAt]
        }
      end
    end

    class Import < T::Struct
      ImportAttributes.apply(self)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(**ImportResponseHelpers.build_common(sym))
      end
    end

    class ImportCreationResponse < T::Struct
      ImportAttributes.apply(self)
      const :upload_url, T.nilable(String)
      const :upload_valid_until, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        attrs = ImportResponseHelpers.build_common(sym).merge(
          upload_url: sym[:uploadUrl],
          upload_valid_until: sym[:uploadValidUntil]
        )
        new(**attrs)
      end
    end

    class ImportListResponse < T::Struct
      const :data, T::Array[Import]
      const :has_more, T.nilable(T::Boolean)
      const :next_cursor, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { Import.from_hash(_1) },
          has_more: sym[:hasMore],
          next_cursor: sym[:nextCursor]
        )
      end
    end

    ImportResponse = T.type_alias { T.any(Import, ImportCreationResponse) }
  end
end
