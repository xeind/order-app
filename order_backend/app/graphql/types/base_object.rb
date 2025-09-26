# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    # Authentication helpers
    def require_authentication!
      raise GraphQL::ExecutionError, "Authentication required" unless current_user
    end

    def require_manager!
      require_authentication!
      raise GraphQL::ExecutionError, "Manager access required" unless current_user.manager?
    end

    def current_user
      context[:current_user]
    end
  end
end
