module Shield::SavePasswordReset
  macro included
    @token : String = ""

    attribute user_email : String

    before_save do
      downcase_user_email

      validate_user_email
      validate_required user_email

      set_user_id
      set_token
      set_ip_address
    end

    after_commit send_mail

    private def downcase_user_email
      user_email.value.try { |value| user_email.value = value.downcase }
    end

    private def validate_user_email
      user_email.value.try do |value|
        user_email.add_error("format invalid") unless value.email?
      end
    end

    private def set_user_id
      user_email.value.try do |value|
        user_id.value = User.from_email(value).try(&.id)
      end
    end

    private def set_token
      if user_id.value
        @token = Random::Secure.urlsafe_base64(32)
        token_hash.value = Login.hash(@token).to_s
      end
    end

    private def set_ip_address
      ip_address.value = nil unless user_id.value
    end

    private def send_mail(password_reset : PasswordReset)
      mail PasswordResetRequestEmail, password_reset, password_reset.url(@token)
    end
  end
end
