module Shield::RequirIpAddress
  macro included
    needs remote_ip : Socket::IPAddress?

    before_save do
      set_ip_address

      validate_required ip_address, message: "could not be determined"
    end

    private def set_ip_address
      remote_ip.try do |value|
        ip_address.value = value
      end
    end
  end
end
