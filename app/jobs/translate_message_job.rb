def translate(text, target_language)
  return text if text.blank?

  @translate_client ||= Google::Cloud::Translate::V2.new(key: ENV.fetch('GOOGLE_TRANSLATE_API_KEY', nil))

  begin
    translation = @translate_client.translate(text, to: target_language)
    translation.text
  rescue StandardError => e
    Rails.logger.error "Translation error: #{e.message}"
    text # エラーの場合、元のテキストを返す
  end
end
