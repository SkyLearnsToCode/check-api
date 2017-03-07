module PenderData
  def validate_pender_result
    if !self.url.blank? && !self.skip_pender
      result = PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
      if (result['type'] == 'error')
        errors.add(:base, I18n.t(:pender_could_not_parse, default: 'Could not parse this media'))
      else
        self.pender_data = result['data']
        # set url with normalized pender URL
        self.url = result['data']['url']
      end
    end
  end

  def set_pender_result_as_annotation
    unless self.pender_data.nil?
      data = self.pender_data
      pender = Bot.where(name: 'Pender').last
      em = Embed.new
      self.overridden_embed_attributes.each{ |k| em.data[k.to_s] = data[k.to_s] } if self.respond_to?('overridden_embed_attributes')
      em.published_at = data['published_at'].to_time.to_i unless data['published_at'].nil?
      em.embed = data.to_json
      em.annotated = self
      em.annotator = pender unless pender.nil?
      em.save!
    end
  end

  def skip_pender
    @skip_pender
  end

  def skip_pender=(bool)
    @skip_pender = bool
  end

  def pender_data
    @pender_data
  end

  def pender_data=(data)
    @pender_data = data
  end
end
