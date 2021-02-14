class DeletePasswordReset < PasswordReset::DeleteOperation
  include Shield::ConfirmDelete
end
