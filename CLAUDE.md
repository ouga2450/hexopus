# CLAUDE.md — Hexopus 実装引き継ぎ資料

## プロジェクト概要

**アプリ名:** Hexopus（ヘキソパス）  
**名前の由来:** Hex（6）+ opus（ラテン語・やるべき仕事）+ octopus（タコ）の造語。6つのタスクを6本足で抱えるタコ。  
**コンセプト:** ADHDでも続けられる、意思決定ゼロの習慣アプリ。タスクを6つに絞り、優先順位順に1つずつ表示。「達成」「スキップ」「今日はここまで」だけで操作できる。やるかどうかで迷わない、ただ片づけるだけ。  
**スタック:** Rails 7 API mode + Angular + PostgreSQL  
**状態:** `rails new` 完了済み。これから実装を開始する。

---

## ディレクトリ構成（想定）

```
focus6/
├── backend/   # Rails API (すでに rails new 済み)
└── frontend/  # Angular (ng new はまだ)
```

---

## DB設計

### users テーブル

| カラム | 型 | 説明 |
|---|---|---|
| id | integer PK | |
| name | string | ユーザー名 |
| email | string | ユニーク制約あり |
| password_digest | string | bcryptハッシュ |
| created_at | datetime | |

### tasks テーブル

| カラム | 型 | 説明 |
|---|---|---|
| id | integer PK | |
| title | string | タスク名 |
| priority | integer | 1〜6の順番（1が最優先） |
| created_at | datetime | |

**バリデーション:** tasksは最大6件まで（Railsで強制する）

### daily_logs テーブル

| カラム | 型 | 説明 |
|---|---|---|
| id | integer PK | |
| task_id | integer FK | tasks.id |
| status | string | `"done"` or `"skip"` のみ |
| logged_on | date | 記録した日付（Date.today） |
| created_at | datetime | |

**制約:** 同じ task_id + logged_on の組み合わせは1件のみ（ユニーク制約）

---

## Rails API エンドポイント一覧

すべて `/api/` namespace 配下に実装する。

### 認証

| メソッド | パス | 説明 |
|---|---|---|
| POST | /api/auth/signup | ユーザー登録（name, email, password） |
| POST | /api/auth/login | ログイン → JWTトークン返却 |

```ruby
# ログインレスポンス
{ "token": "eyJ...", "user": { "id": 1, "name": "太郎", "email": "taro@example.com" } }
```

### タスク管理

| メソッド | パス | 説明 |
|---|---|---|
| GET | /api/tasks | タスク一覧（priority昇順） |
| POST | /api/tasks | タスク追加（6件上限チェック） |
| PATCH | /api/tasks/reorder | 優先順位の一括更新 |
| DELETE | /api/tasks/:id | タスク削除 |

### フォーカス（メイン機能）

| メソッド | パス | 説明 |
|---|---|---|
| GET | /api/focus/current | 今日まだ未処理の最高優先タスクを1件返す |
| POST | /api/focus/log | 達成 or スキップを記録する |

### 振り返り

| メソッド | パス | 説明 |
|---|---|---|
| GET | /api/review/today | 今日の達成数・スキップ数を返す |

---

## 各エンドポイントの実装仕様

### GET /api/focus/current

今日のdaily_logsにまだ記録されていない、最もpriorityが小さいtaskを返す。

```ruby
# 期待するレスポンス（タスクが残っている場合）
{
  "id": 3,
  "title": "Rails学習",
  "priority": 2
}

# 全タスク完了 or 「今日はここまで」の場合
{ "current": null }
```

### POST /api/focus/log

```ruby
# リクエストボディ
{ "task_id": 3, "status": "done" }  # or "skip"

# レスポンス
{ "logged_on": "2026-03-27", "status": "done" }
```

### POST /api/tasks（6件上限）

```ruby
# 6件すでにある場合のエラーレスポンス
# status: 422
{ "error": "タスクは6件までです" }
```

### PATCH /api/tasks/reorder

```ruby
# リクエストボディ
{ "order": [5, 2, 8, 1, 4, 3] }  # task idを優先順に並べた配列

# レスポンス
{ "ok": true }
```

### GET /api/review/today

```ruby
# レスポンス
{
  "done": 3,
  "skip": 1,
  "remaining": 2,
  "total": 6
}
```

---

## 実装ステップ（推奨順）

### Step 1: DB・モデル

```bash
rails g model Task title:string priority:integer
rails g model DailyLog task:references status:string logged_on:date
rails db:migrate
```

- Task: `validates :title, presence: true` / `validate :max_six_tasks`
- DailyLog: `validates :status, inclusion: { in: %w[done skip] }` / unique index on `[task_id, logged_on]`

### Step 2: ルーティング

```ruby
# config/routes.rb
namespace :api do
  resources :tasks, only: [:index, :create, :destroy] do
    collection { patch :reorder }
  end

  namespace :focus do
    get  :current
    post :log
  end

  namespace :review do
    get :today
  end
end
```

### Step 3: コントローラー（実装順）

1. `Api::TasksController` — CRUD + reorder
2. `Api::Focus::CurrentController` — 今日の未処理タスクを返すロジック
3. `Api::Focus::LogController` — done/skip の記録
4. `Api::Review::TodayController` — 集計

### Step 4: CORS設定

```ruby
# Gemfile
gem "rack-cors"

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:4200"
    resource "*", headers: :any, methods: [:get, :post, :patch, :delete, :options]
  end
end
```

### Step 5: Angular（ng new の後）

```bash
ng new frontend --routing --style=css
```

**画面構成:**

| コンポーネント | パス | 役割 |
|---|---|---|
| FocusComponent | /focus | メイン。1タスクだけ表示、3択ボタン |
| ReviewComponent | /review | 振り返り。達成/スキップ数を表示 |
| TasksComponent | /tasks | タスク管理。追加・削除・並び替え |

**Serviceファイル:**
- `task.service.ts` — tasks APIの呼び出し
- `focus.service.ts` — focus APIの呼び出し
- `review.service.ts` — review APIの呼び出し

---

## フォーカス画面のUXルール（実装時に守ること）

- 表示するのは **タスク名1つだけ**
- ボタンは **「達成」「スキップ」「今日はここまで」の3つだけ**
- 全タスク処理済み or「今日はここまで」押下 → `/review` に自動遷移
- 余計な情報（進捗バー、連続日数など）はフォーカス画面には出さない

---

## 振り返り画面のUXルール

- 「達成 N個 / スキップ N個」のみ表示
- 「明日またがんばる」ボタン → `/focus` に戻る
- 分析・グラフは不要（シンプルに保つ）

---

## 今日のタスク選定ロジック（Railsの核心部分）

```ruby
# app/controllers/api/focus/current_controller.rb のイメージ

logged_today = DailyLog.where(logged_on: Date.today).pluck(:task_id)
current_task = Task.where.not(id: logged_today).order(:priority).first

render json: current_task ? current_task : { current: nil }
```

---

## 注意事項

- `rails new` は完了済み。`--api` フラグが付いているか確認すること。
- DBはPostgreSQLを使う。
- Angularのバージョンは最新安定版でOK。
- 認証はJWTのみで実装する。Deviseは使わない。
- `bcrypt` でパスワードハッシュ化、`jwt` gem でトークン発行・検証。
- テストは今回のスコープ外。動くものを優先する。
