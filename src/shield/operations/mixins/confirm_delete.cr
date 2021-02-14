module Shield::ConfirmDelete
  macro included
    attribute confirmation : Bool

    before_delete do
      validate_required confirmation
      validate_acceptance_of confirmation, message: "has failed"
    end
  end
end
