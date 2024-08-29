module TranslationService
  class Simple < TranslationService::Base
    def initialize
      # No special initialization required for this simple service
    end

    # @param [String] key
    # @param [String] to
    # @param [String | nil] from
    # @return [String]
    def translate(key, to = :en, from = nil)
      # Simple lookup implementation
      translations = {
        en: {
          'subject' => 'Subject',
          'add_teacher' => 'Add Teacher',
          'availabilities' => 'Availabilities',
          'chat' => 'Chat',
          'book' => 'Book',
          'date' => 'Date',
          'times_subject_to_change' => 'Times are subject to change',
          'view_more' => 'View More'
        },
        ja: {
          'subject' => '教科',
          'add_teacher' => '先生を追加',
          'availabilities' => '予約可能時間',
          'chat' => 'チャット',
          'book' => '予約する',
          'date' => '日付',
          'times_subject_to_change' => '時間は変更される場合があります',
          'view_more' => 'もっと見る'
        }
      }
      translations.dig(to.to_sym, key) || key
    end

    # @param [String] key
    # @param [String] to
    # @param [String | nil] from
    # @return [String]
    def t(key, to = :en, from = nil)
      translate(key, to, from)
    end
  end
end
