class ClientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Example: return all records for simplicity; customize as needed
      scope.all
    end
  end

  def index?
    true # or your authorization logic here
  end

  def show?
    true # or your authorization logic here
  end
end
