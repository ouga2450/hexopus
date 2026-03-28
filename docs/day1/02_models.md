# Day 1-② モデル・マイグレーション

## モデルとは？

**モデル** = DBのテーブル1つに対応するRubyのクラス。
テーブルのデータを読み書きするメソッドが使えるようになる。

---

## 今回作るテーブル

### tasks（タスク）

| カラム | 型 | 説明 |
|---|---|---|
| id | integer | 自動採番（書かなくていい） |
| title | string | タスク名 |
| priority | integer | 1〜6の順番（1が最優先） |
| created_at | datetime | 自動（書かなくていい） |

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
# backendディレクトリで実行
cd backend

rails g model Task title:string priority:integer
rails g model DailyLog task:references status:string logged_on:date
```

**`rails g model`** はモデルファイルとマイグレーションファイルを同時に作るコマンド。

**`task:references`** は `task_id` カラム（外部キー）を自動で作る書き方。

実行すると以下が生成される：
```
app/models/task.rb
app/models/daily_log.rb
db/migrate/20xxxxxx_create_tasks.rb
db/migrate/20xxxxxx_create_daily_logs.rb
```

---

## マイグレーションとは？

**マイグレーション** = DBのテーブル構造を変更する手順書。
`db/migrate/` に時系列で保存されるので、チームで共有・再現できる。

生成されたファイルを確認してみよう：

```ruby
# db/migrate/xxxxxx_create_tasks.rb
class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.integer :priority

      t.timestamps
    end
  end
end
```

---

## ユニーク制約を追加する

`daily_logs` は同じタスクを同じ日に2回記録できないようにする。
マイグレーションファイルに手動で追加する：

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
# app/models/task.rb
class Task < ApplicationRecord
  has_many :daily_logs, dependent: :destroy

  validates :title, presence: true    # タイトルは必須
  validates :priority, presence: true

  validate :max_six_tasks             # カスタムバリデーション

  private

  def max_six_tasks
    # 新規作成のときだけチェック
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

  validates :status, inclusion: { in: %w[done skip] }  # done か skip だけ許可
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
rails console   # または rails c
```

```ruby
# タスクを作ってみる
Task.create(title: "Rails学習", priority: 1)
Task.all    # 一覧表示
Task.count  # 件数
```

---

## 次のステップ

→ [Day 2: 03_routing.md](../day2/03_routing.md) でURLの設定をする
