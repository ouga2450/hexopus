# Day 2-① ルーティング

## ルーティングとは？

**URL × HTTPメソッド** を「どのコントローラーのどのメソッドで処理するか」に対応させる設定。

```
POST /api/auth/login  →  Api::AuthController#login
GET  /api/tasks       →  Api::TasksController#index
```

設定ファイル: `config/routes.rb`

---

## HTTPメソッドとは？

| メソッド | 用途 | 例 |
|---|---|---|
| GET | データを取得する | タスク一覧を見る |
| POST | データを作成する | タスクを追加する、ログインする |
| PATCH | データを更新する | 優先順位を変える |
| DELETE | データを削除する | タスクを消す |

---

## Hexopusのルーティング

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    # 認証（JWTトークン発行）
    post "auth/signup", to: "auth#signup"
    post "auth/login",  to: "auth#login"

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

### `post "auth/signup", to: "auth#signup"`
`/api/auth/signup` への POST を `Api::AuthController#signup` に対応させる。

### `resources :tasks, only: [...]`
一般的なCRUDのルートをまとめて作るショートカット。

| only の値 | メソッド | URL | コントローラーのメソッド |
|---|---|---|---|
| :index | GET | /api/tasks | tasks#index |
| :create | POST | /api/tasks | tasks#create |
| :destroy | DELETE | /api/tasks/:id | tasks#destroy |

### `collection { patch :reorder }`
`/api/tasks/reorder` に `PATCH` リクエストを受け付ける。

---

## 認証が必要なルートとそうでないルート

`auth/signup` と `auth/login` 以外は **JWTトークンが必要**。
`ApplicationController` で `before_action :authenticate!` を設定し、認証が必要なエンドポイントを守る。

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    # 詳細は 04_controllers.md で説明する
  end
end
```

---

## 確認コマンド

```bash
docker compose exec web rails routes | grep api
```

以下のようなルート一覧が表示されれば成功：

```
POST   /api/auth/signup        api/auth#signup
POST   /api/auth/login         api/auth#login
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

→ [04_controllers.md](04_controllers.md) でコントローラーとJWT認証を実装する
