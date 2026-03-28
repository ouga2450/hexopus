# Day 2-③ CORS設定

## CORSとは？

**CORS（Cross-Origin Resource Sharing）** = 異なるオリジン間のリクエストを制御する仕組み。

ブラウザはセキュリティのため、**別のURL（オリジン）へのリクエストをデフォルトで拒否**する。

```
Angular: http://localhost:4200
Rails:   http://localhost:3000   ← 別のポート = 別オリジン
```

このままだとAngularからRailsへのリクエストがブラウザにブロックされる。
RailsにCORSを設定して「`localhost:4200` からのリクエストは許可する」と明示する。

---

## CORS設定ファイル

今回は `rack-cors` がすでにインストール済み。設定ファイルを確認・修正する。

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:4200"

    resource "*",
      headers: :any,
      methods: [:get, :post, :patch, :delete, :options],
      expose: ["Authorization"]  # ← JWTトークンをレスポンスヘッダーで受け取れるようにする
  end
end
```

### ポイント解説

**`origins`** — どのURLからのリクエストを許可するか。

**`methods`** — 許可するHTTPメソッド。`:options` はブラウザの事前確認リクエスト（プリフライト）のために必要。

**`expose: ["Authorization"]`** — レスポンスヘッダーの `Authorization` をブラウザのJavaScriptから読めるようにする。これがないとAngular側でトークンを取得できない場合がある。

---

## 確認方法

Railsサーバーを再起動してから：

```bash
curl -I -X OPTIONS http://localhost:3000/api/tasks \
  -H "Origin: http://localhost:4200"
```

レスポンスヘッダーに以下があれば成功：
```
Access-Control-Allow-Origin: http://localhost:4200
```

---

## 次のステップ

→ [Day 3: 06_angular_intro.md](../day3/06_angular_intro.md) でAngularを始める
