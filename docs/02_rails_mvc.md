# 02 - 普通のRailsアプリ（MVC）

[← 目次に戻る](./00_index.md)

---

## MVCとは

RailsにはMVCという設計パターンがあります。

| 文字 | 名前 | 役割 |
|------|------|------|
| M | Model | データを管理する |
| V | View | HTMLを作って画面を返す |
| C | Controller | リクエストを受けてModelとViewをつなぐ |

---

## サーバーサイドレンダリング

普通のRailsアプリでは、ブラウザがアクセスするとサーバーがHTMLを丸ごと作って返します。
これを **サーバーサイドレンダリング** と呼びます。

```
ブラウザ → 「/posts ページをください」
                ↓
           Controller → Model → データ取得
                ↓
           View（.erbファイル） → HTMLを生成
                ↓
ブラウザ ← HTMLを返す → 画面に表示
```

### ファイル構成

```
app/
├── models/
│   └── post.rb              ← データの定義
├── views/
│   └── posts/
│       └── index.html.erb   ← HTMLのテンプレート
└── controllers/
    └── posts_controller.rb  ← リクエストを処理
```

### Viewファイル（.erb）の例

```erb
<h1>投稿一覧</h1>
<% @posts.each do |post| %>
  <p><%= post.title %></p>
<% end %>
```

RubyのコードとHTMLが混在しています。
サーバー側でHTMLに変換されてから返されます。

---

[次へ → 03 - Rails API + Angularの構成](./03_rails_api_angular.md)
