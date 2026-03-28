# Day 2-① ルーティング

## ルーティングとは？

**URL × HTTPメソッド** を「どのコントローラーのどのメソッドで処理するか」に対応させる設定。

```
GET /api/tasks  →  Api::TasksController#index
```

設定ファイル: `config/routes.rb`

---

## HTTPメソッドとは？

| メソッド | 用途 | 例 |
|---|---|---|
| GET | データを取得する | タスク一覧を見る |
| POST | データを作成する | タスクを追加する |
| PATCH | データを更新する | 優先順位を変える |
| DELETE | データを削除する | タスクを消す |

---

## Hexopusのルーティング

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    # タスク管理
    resources :tasks, only: [:index, :create, :destroy] do
      collection { patch :reorder }
    end

    # フォーカス機能
    namespace :focus do
      get  :current
      post :log
    end

    # 振り返り
    namespace :review do
      get :today
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## コードの読み方

### `namespace :api`
URLの先頭に `/api` を付ける。コントローラーは `Api::` から始まる。

### `resources :tasks, only: [...]`
`resources` は一般的なCRUDのルートをまとめて作るショートカット。

| only の値 | メソッド | URL | コントローラーのメソッド |
|---|---|---|---|
| :index | GET | /api/tasks | tasks#index |
| :create | POST | /api/tasks | tasks#create |
| :destroy | DELETE | /api/tasks/:id | tasks#destroy |

### `collection { patch :reorder }`
`resources` の中で特別なルートを追加する書き方。
`/api/tasks/reorder` に `PATCH` リクエストを受け付ける。

### `namespace :focus`
URLに `/focus` を付ける。コントローラーは `Api::Focus::` の下に置く。

---

## 確認コマンド

```bash
rails routes | grep api
```

以下のようなルート一覧が表示されれば成功：

```
GET    /api/tasks              api/tasks#index
POST   /api/tasks              api/tasks#create
PATCH  /api/tasks/reorder      api/tasks#reorder
DELETE /api/tasks/:id          api/tasks#destroy
GET    /api/focus/current      api/focus/current#index
POST   /api/focus/log          api/focus/log#create
GET    /api/review/today       api/review/today#index
```

---

## 次のステップ

→ [04_controllers.md](04_controllers.md) でコントローラーを実装する
