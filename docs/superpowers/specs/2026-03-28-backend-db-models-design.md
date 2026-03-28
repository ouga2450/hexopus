# 設計スペック: バックエンド DB + モデル実装

**日付:** 2026-03-28
**スコープ:** users・tasks テーブルの作成と対応モデルの実装
**スタック:** Rails 8 API + PostgreSQL

---

## スコープ

今回実装するもの:
1. `bcrypt` gem の有効化
2. `users` テーブルのマイグレーション
3. `tasks` テーブルのマイグレーション
4. `User` モデル実装
5. `Task` モデル実装

今回スコープ外（次回以降）:
- 認証API（signup / login）
- タスクAPI（CRUD）
- `daily_logs` テーブル
- フォーカス・振り返り機能
- Angular フロントエンド

---

## Gemfile

```ruby
gem "bcrypt", "~> 3.1.7"  # コメントアウト解除
# jwt は認証API実装時に追加
```

---

## マイグレーション

### users テーブル

```ruby
create_table :users do |t|
  t.string :name,            null: false
  t.string :email,           null: false
  t.string :password_digest, null: false
  t.timestamps
end
add_index :users, :email, unique: true
```

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | integer PK | | |
| name | string | NOT NULL | ユーザー名 |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| password_digest | string | NOT NULL | bcryptハッシュ化済みパスワード |
| created_at | datetime | | |
| updated_at | datetime | | |

### tasks テーブル

```ruby
create_table :tasks do |t|
  t.references :user,     null: false, foreign_key: true
  t.string     :title,    null: false
  t.integer    :priority, null: false
  t.timestamps
end
```

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | integer PK | | |
| user_id | integer FK | NOT NULL | users.id への外部キー |
| title | string | NOT NULL | タスク名 |
| priority | integer | NOT NULL | 優先順位（クライアントが指定） |
| created_at | datetime | | |
| updated_at | datetime | | |

**補足:**
- `priority` の一意性制約なし（同値を許容、並び順はクライアント管理）
- `daily_logs` テーブルは後のフェーズで追加

---

## モデル

### User モデル

```ruby
class User < ApplicationRecord
  has_secure_password
  validates :name,  presence: true
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  has_many :tasks, dependent: :destroy
end
```

**has_secure_password の動作:**
- `password` セッターが自動定義され、bcryptハッシュを `password_digest` に保存
- `user.authenticate("パスワード")` で認証（成功時はuserオブジェクト、失敗時はfalse）
- パスワードの復元は不可能（一方向ハッシュ）

### Task モデル

```ruby
class Task < ApplicationRecord
  belongs_to :user
  validates :title,    presence: true
  validates :priority, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validate  :max_six_tasks

  private

  def max_six_tasks
    errors.add(:base, "タスクは6件までです") if user.tasks.count >= 6
  end
end
```

**max_six_tasks バリデーション:**
- ユーザーごとに最大6件を強制
- 6件以上の場合は `422 Unprocessable Entity` を返す想定（コントローラー実装時）

---

## 次のステップ

1. **認証API** — `POST /api/auth/signup`, `POST /api/auth/login`（jwt gem を追加）
2. **タスクAPI** — `GET/POST/DELETE /api/tasks`（認証済みユーザーのみ）
3. **フォーカス機能** — `daily_logs` テーブル追加後に実装
