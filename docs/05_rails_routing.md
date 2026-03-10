# 05 - Railsのルーティング

[← 目次に戻る](./00_index.md)

---

## ルーティングとは

「このURLにリクエストが来たら、どのコントローラーのどのアクションを実行するか」を決めるものです。

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    get "hello", to: "hello#index"
  end
end
```

```
GET /api/hello  →  Api::HelloController の index アクション
```

---

## namespaceとapi/フォルダ

### なぜ `api/` フォルダを作るのか

普通のRailsアプリではコントローラーをそのまま置きます：

```
app/controllers/
└── posts_controller.rb   ← フォルダなし

URL: /posts
```

Rails APIではフォルダを分けます：

```
app/controllers/
└── api/
    └── hello_controller.rb   ← api/ フォルダの中

URL: /api/hello
```

URLに `/api/` を付けることで **「これはAPIへのリクエスト（JSONを返す）」** と
一目でわかるようにします。

### namespaceの役割

`namespace :api` と書くと2つのことが同時に起きます：

1. URLに `/api/` が自動で付く
2. `module Api` の中のコントローラーを探す

```ruby
namespace :api do
  get "hello", to: "hello#index"
  # → GET /api/hello → Api::HelloController#index
end
```

---

## バージョン管理

`api/` フォルダを作ることで将来バージョン管理もできます：

```ruby
namespace :api do
  namespace :v1 do
    get "hello", to: "hello#index"   # /api/v1/hello
  end
  namespace :v2 do
    get "hello", to: "hello#index"   # /api/v2/hello
  end
end
```

古いバージョンを残しながら新しいバージョンを追加できるので、
既存ユーザーへの影響なく機能を更新できます。

---

[次へ → 06 - Railsのコントローラー](./06_rails_controller.md)
