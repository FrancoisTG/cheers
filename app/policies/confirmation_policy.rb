class ConfirmationPolicy < ApplicationPolicy


#only for Index or specific show
  class Scope < Scope
    def resolve
      scope.all
    end
  end

#  def show?
#    true  # Anyone Logged In can view a confirmation
#  end
#
  def create?
    true  # Anyone Logged In can create a confirmation
  end
#
#  def update?
#    record.user == user  # Only confirmation creator can update it
# end
  def close_vote?
    true
  end

  def destroy?
    true
    # record.user == user  # Only confirmation creator can update it
  end
end
