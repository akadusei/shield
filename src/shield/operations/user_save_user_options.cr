module Shield::UserSaveUserOptions
  macro included
    attribute login_notify : Bool
    attribute password_notify : Bool

    before_save do
      require_login_notify
      require_password_notify

      update_user_options
    end

    after_save create_user_options

    private def require_login_notify
      return if persisted? || !login_notify.value.nil?
      validate_required login_notify
    end

    private def require_password_notify
      return if persisted? || !password_notify.value.nil?
      validate_required password_notify
    end

    # Update user options when updating user
    #
    # This is run in `before_save` because `after_save`
    # (and `after_commit`) does not run if no db table column
    # attribute changes.
    #
    # This means, if you call `Save(Current)User.update` with only
    # `login_notify` and `password_notify` passed, `after_save` never
    # runs, because those 2 are not actual db table columns (they are
    # virtual columns)
    private def update_user_options
      return unless persisted?

      SaveUserOptions.update(
        record.not_nil!.options!,
        login_notify: login_notify.value.nil? ?
          Nothing.new :
          login_notify.value.not_nil!,
        password_notify: password_notify.value.nil? ?
          Nothing.new :
          password_notify.value.not_nil!
      ) do |operation, user_options|
        forward_errors(operation)
      end
    end

    # Create user options when creating user
    #
    # Why are we `rescue`ing?:
    #
    # `#persisted?` returns `true`, always, in `after_save` (and
    # `after_commit`), so it is not a viable method for checking
    # whether or not we did a create (vs. update) operation here.
    private def create_user_options(user : User)
      user.options!
    rescue Avram::RecordNotFoundError
      SaveUserOptions.create!(
        user_id: user.id,
        login_notify: login_notify.value.not_nil!,
        password_notify: password_notify.value.not_nil!
      )
    end

    private def forward_errors(operation)
      operation.login_notify.errors.each do |error|
        login_notify.add_error(error)
      end

      operation.password_notify.errors.each do |error|
        password_notify.add_error(error)
      end
    end
  end
end
