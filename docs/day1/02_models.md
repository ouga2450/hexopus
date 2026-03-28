# Day 1-② モデル・マイグレーション

## モデルとは？

**モデル** = DBのテーブル1つに対応するRubyのクラス。
テーブルのデータを読み書きするメソッドが使えるようになる。

---

## 今回作るテーブル

### users（ユーザー）

| カラム | 型 | 説明 |
|---|---|---|
| id | integer | 自動採番 |
| name | string | ユーザー名 |
| email | string | ユニーク制約あり |
| password_digest | string | bcryptでハッシュ化されたパスワード |
| created_at | datetime | 自動 |

### tasks（タスク）

| カラム | 型 | 説明 |
|---|---|---|
| id | integer | 自動採番 |
| title | string | タスク名 |
| priority | integer | 1〜6の順番（1が最優先） |
| created_at | datetime | 自動 |

### daily_logs（日次記録）

| カラム | 型 | 説明 |
|---|---|---|
| id | integer | 自動採番 |
| task_id | integer | どのタスクか（FK） |
| status | string | `"done"` または `"skip"` |
| logged_on | date | 記録した日付 |
| created_at | datetime | 自動 |

---

## モデル生成コマンド

```bash
rails g model User name:string email:string password_digest:string
rails g model Task title:string priority:integer
rails g model DailyLog task:references status:string logged_on:date
```

**`rails g model`** はモデルファイルとマイグレーションファイルを同時に作るコマンド。

**`task:references`** は `task_id` カラム（外部キー）を自動で作る書き方。

---

## マイグレーションを修正する

### users にユニーク制約を追加

```ruby
# db/migrate/xxxxxx_create_users.rb
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true  # メールアドレスの重複禁止
  end
end
```

### daily_logs にユニーク制約を追加

```ruby
# db/migrate/xxxxxx_create_daily_logs.rb
class CreateDailyLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_logs do |t|
      t.references :task, null: false, foreign_key: true
      t.string :status
      t.date :logged_on

      t.timestamps
    end

    # 同じ task_id + logged_on の組み合わせを禁止
    add_index :daily_logs, [:task_id, :logged_on], unique: true
  end
end
```

---

## マイグレーション実行

```bash
rails db:migrate
```

成功したら `db/schema.rb` が更新される。確認してみよう。

---

## モデルにバリデーションを追加する

**バリデーション** = データを保存する前にチェックするルール。

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password  # bcryptでパスワードをハッシュ化する（password_digestが必要）

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_digest_changed?
end
```

**`has_secure_password`** を使うと：
- `password` と `password_confirmation` の属性が自動で追加される
- `user.authenticate("パスワード")` でパスワードを検証できる
- DBには `password_digest`（ハッシュ値）だけ保存される

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  has_many :daily_logs, dependent: :destroy

  validates :title, presence: true
  validates :priority, presence: true

  validate :max_six_tasks

  private

  def max_six_tasks
    if new_record? && Task.count >= 6
      errors.add(:base, "タスクは6件までです")
    end
  end
end
```

```ruby
# app/models/daily_log.rb
class DailyLog < ApplicationRecord
  belongs_to :task

  validates :status, inclusion: { in: %w[done skip] }
  validates :logged_on, presence: true
end
```

### `has_many` / `belongs_to` とは？

```
Task  has_many :daily_logs   → タスクは複数のログを持つ
DailyLog  belongs_to :task   → ログは1つのタスクに属する
```

`dependent: :destroy` = タスクを削除したとき、関連するログも一緒に削除する。

---

## 動作確認（Railsコンソール）

```bash
docker compose exec web rails console
```

```ruby
# ユーザーを作ってみる
user = User.create(name: "太郎", email: "taro@example.com", password: "password123")
user.authenticate("password123")  # => userオブジェクト（成功）
user.authenticate("wrong")        # => false（失敗）

# タスクを作ってみる
Task.create(title: "Rails学習", priority: 1)
Task.all
```

---

## 次のステップ

→ [Day 2: 03_routing.md](../day2/03_routing.md) でURLの設定をする
