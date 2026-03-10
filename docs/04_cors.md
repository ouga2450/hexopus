# 04 - CORSとは

[← 目次に戻る](./00_index.md)

---

## 同一オリジンポリシー

ブラウザには「同一オリジンポリシー」というセキュリティルールがあります。
「オリジン」とは `プロトコル + ドメイン + ポート` の組み合わせです。

```
http://localhost:4200  ← Angular のオリジン
http://localhost:3000  ← Rails のオリジン

ポートが違う → 別オリジン → ブラウザがリクエストをブロックする！
```

### なぜこのルールがあるのか

悪意のあるサイトが勝手に別サービスのAPIを叩くのを防ぐためです。

```
悪意のあるサイト (evil.com) → あなたの銀行API (bank.com)
                              ← ブロック！（CORSエラー）
```

---

## CORSとは

**CORS（Cross-Origin Resource Sharing）** は
「このオリジンからのアクセスは許可する」とサーバーがブラウザに伝える仕組みです。

```
Angular → Railsにリクエスト
Rails   → レスポンスに「localhost:4200はOK」というヘッダーを付けて返す
ブラウザ → ヘッダーを確認してOKならデータを通す
```

---

## rack-corsの設定

### Gemfileに追加

```ruby
gem "rack-cors"
```

Gemとは、Rubyで使えるライブラリのことです。

### cors.rbで許可するオリジンを設定

`backend/config/initializers/cors.rb`

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:4200"   # Angularからのアクセスを許可

    resource "*",                     # すべてのAPIパスに適用
      headers: :any,                  # どんなヘッダーも許可
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

`initializers/` フォルダのファイルはRails起動時に自動で読み込まれます。

---

## 本番環境での考え方

本番ではフロントとバックを同じドメインで配信することが多く、
その場合はCORSの設定が不要になります。

```
開発環境: localhost:4200 と localhost:3000 → 別オリジン → CORS必要
本番環境: myapp.com と myapp.com/api      → 同一オリジン → CORS不要
```

別ドメインで運用する場合は本番用のドメインを許可します：

```ruby
origins Rails.env.production? ? "https://app.myapp.com" : "http://localhost:4200"
```

---

[次へ → 05 - Railsのルーティング](./05_rails_routing.md)
