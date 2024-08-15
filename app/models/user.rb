class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :first_name, presence: true, length: { in: 1..100 }
  validates :last_name, presence: true, length: { in: 1..100 }

  has_many :bookings
  has_one_attached :photo
  belongs_to :current_teacher, class_name: 'User', optional: true
  attribute :language, :integer

  enum state: {
    initial: 0,
    awaiting_booking_type: 1,
    awaiting_slot_selection: 2,
    awaiting_change_selection: 3,
    awaiting_cancel_selection: 4,
    awaiting_new_slot: 5
  }

  enum language: {
    japanese: 0,
    english: 1
  }, _prefix: true

  validates :line_user_id, uniqueness: true, allow_nil: true

  # LINEユーザーIDでユーザーを検索作成
  def self.find_or_create_by_line_user_id(line_user_id)
    find_or_create_by(line_user_id:) do |user|
      user.email = "#{line_user_id}@example.com" # 仮のメールアドレス
      user.password = SecureRandom.hex(10) # ランダムなパスワード
      user.language = :japanese # デフォルト言語を設定
      user.first_name = "LINE User" # 仮の名前
      user.last_name = line_user_id.last(6) # LINE IDの最後の6文字を苗字として使用
    end
  end

  # 利用可能なスロットを取得するメソッド
  def available_slots
    # この実装は仮のものです。実際のロジックに合わせて修正してください。
    [Time.now + 1.day, Time.now + 2.days, Time.now + 3.days]
  end
end
