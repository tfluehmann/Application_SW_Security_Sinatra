class Customer < Sequel::Model
  def to_h
    {
      name: name,
      last_name: last_name,
      address: address
    }
  end

  def to_json
    to_h.to_json
  end
end
