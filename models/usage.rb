class Usage < OpenStruct

  def to_json(j)
    {
      time_stamp: time_stamp,
      stroom_dal: stroom_dal,
      stroom_piek: stroom_piek,
      stroom_totaal: stroom_totaal,
      gas: gas
    }.to_json(j)
  end
end
