# Rails × Angular 入門

ゼロからRailsとAngularの連携を理解するための教材です。

---

## 第1章：Webアプリの基本構造

### クライアントとサーバー

Webアプリは大きく2つの役割に分かれています。

```
クライアント（ブラウザ）        サーバー
┌──────────────────┐          ┌──────────────────┐
│ 画面を表示する    │ ←→ HTTP  │ データを処理する  │
│ ユーザーの操作    │          │ データを保存する  │
└──────────────────┘          └──────────────────┘
```

**HTTP** はクライアントとサーバーが会話するためのルールです。
クライアントが「リクエスト」を送り、サーバーが「レスポンス」を返します。

```
クライアント: 「/api/hello のデータをください（GETリクエスト）」
サーバー:     「はい、これがデータです（レスポンス）」
```

---

## 第2章：普通のRailsアプリ（MVC）

### MVCとは

RailsにはMVCという設計パターンがあります。

```
M（Model）      データを管理する
V（View）       HTMLを作って画面を返す
C（Controller） リクエストを受けてModelとViewをつなぐ
```

普通のRailsアプリでは、ブラウザがアクセスするとサーバーがHTMLを丸ごと作って返していました。

```
ブラウザ → 「ページをください」
              ↓
           Controller → Model → データ取得
              ↓
           View → HTML を生成
              ↓
ブラウザ ← HTML を返す → 画面に表示
```

---

## 第3章：Rails API + Angularの構成

### なぜ分離するのか

普通のRailsアプリでは「画面の生成」もサーバーが行います。
これをフロントエンドとバックエンドに分離する構成が増えています。

| | 普通のRails | Rails API + Angular |
|---|---|---|
| 画面の生成 | サーバー側 | ブラウザ側（Angular） |
| サーバーの負荷 | 高い | 低い |
| 画面の更新 | ページ全体をリロード | 必要な部分だけ更新 |
| スマホアプリとの共用 | できない | 同じAPIを使える |

### Viewの役割がAngularに移る

```
普通のRails
  M（Model）      → データを管理
  V（View）       → HTMLを生成して返す  ← app/views/ の .erb ファイル
  C（Controller） → リクエストを処理

Rails API + Angular
  M（Model）      → データを管理
  V（View）       → Angularが担当！（app/views/ は使わない）
  C（Controller） → リクエストを受けてJSONだけを返す
```

Railsは **JSONを返すことだけ** に専念します。
画面の作成・表示はすべてAngularが担います。

### このプロジェクトの構成

```
┌─────────────────────────────────────────────┐
│  フロントエンド（Angular）  localhost:4200   │
│  ブラウザで動く。画面の表示を担当。          │
└─────────────────────────────────────────────┘
              ↑↓ JSONでデータをやり取り
┌─────────────────────────────────────────────┐
│  バックエンド（Rails API）  localhost:3000   │
│  サーバーで動く。データの処理を担当。        │
└─────────────────────────────────────────────┘
```

---

## 第4章：JSONとは

RailsとAngularはJSON形式でデータをやり取りします。

```json
{
  "message": "こんにちは！FocusFlowへようこそ"
}
```

キーと値のペアで構成されたテキストです。
プログラムの言語に関係なく読み書きできるのが特徴です。

```json
{
  "name": "田中",
  "age": 25,
  "tasks": ["企画書を書く", "メール返信"]
}
```

---

## 第5章：CORSとは

### なぜ必要か

ブラウザには「同一オリジンポリシー」というセキュリティルールがあります。
「オリジン」とは `プロトコル + ドメイン + ポート` の組み合わせです。

```
http://localhost:4200  ← Angular のオリジン
http://localhost:3000  ← Rails のオリジン

ポートが違う → 別オリジン → ブラウザがリクエストをブロックする！
```

このルールはセキュリティのための仕組みです。
悪意のあるサイトが勝手に別サービスのAPIを叩くのを防いでいます。

```
悪意のあるサイト (evil.com) → あなたの銀行API (bank.com)
                              ← ブロック！（CORSエラー）
```

### CORSで解決する

**CORS（Cross-Origin Resource Sharing）** は
「このオリジンからのアクセスは許可する」とサーバーがブラウザに伝える仕組みです。

```
Angular → Railsにリクエスト
Rails   → レスポンスに「localhost:4200はOK」というヘッダーを付けて返す
ブラウザ → ヘッダーを確認してOKならデータを通す
```

### rack-corsとは

RailsでCORSを設定するためのGem（ライブラリ）です。

### 本番環境では

本番ではフロントとバックを同じドメインで配信することが多く、
その場合はCORSの設定が不要になります。

```
開発環境: localhost:4200 と localhost:3000 → 別オリジン → CORS必要
本番環境: myapp.com と myapp.com/api      → 同一オリジン → CORS不要
```

---

## 第6章：Rails側の実装

### ① Gemfileにrack-corsを追加

`backend/Gemfile`

```ruby
gem "rack-cors"
```

Gemfileはプロジェクトで使うライブラリの一覧です。
ここに書くことで「このGemを使う」と宣言します。

---

### ② CORSの設定

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

### ③ コントローラーを作成

#### なぜ `api/` フォルダを作るのか

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
一目でわかるようにします。将来バージョン管理もできます：

```
/api/v1/hello   ← 古いバージョン（既存ユーザーはそのまま使える）
/api/v2/hello   ← 新しいバージョン
```

#### モジュールとは

Rubyには「ファイルの場所とモジュール名を一致させる」というルールがあります。

```
ファイル: controllers/api/hello_controller.rb
                      ↑
              このフォルダ名に合わせて…

コード:
module Api               ← api/ フォルダに対応
  class HelloController
  end
end
```

モジュールは「グループの名前」です。

```ruby
# グループなし → HelloController という名前
class HelloController
end

# グループあり → Api::HelloController という名前
module Api
  class HelloController
  end
end
```

`Api::HelloController` と書くことで「ApiグループのHelloController」という意味になり、
他のグループの同名クラスと区別できます。

#### コントローラーのコード

`backend/app/controllers/api/hello_controller.rb`

```ruby
module Api
  class HelloController < ApplicationController
    def index
      render json: { message: "こんにちは！FocusFlowへようこそ" }
    end
  end
end
```

- `module Api` → `api/` フォルダに対応するグループ名
- `class HelloController` → コントローラーの名前
- `def index` → アクション（GETリクエストに対する処理）
- `render json: { ... }` → JSONを返す

---

### ④ ルーティングを設定

`backend/config/routes.rb`

```ruby
Rails.application.routes.draw do
  namespace :api do
    get "hello", to: "hello#index"
  end
end
```

ルーティングは「このURLにリクエストが来たら、どのコントローラーのどのアクションを実行するか」を決めます。

```
GET /api/hello  →  Api::HelloController の index アクション
```

- `namespace :api` → URLに `/api/` を付ける＋`module Api` の中を探す
- `get "hello"` → GETリクエストの `/api/hello` を受け付ける
- `to: "hello#index"` → `hello_controller.rb` の `index` メソッドを実行

#### フォルダ・モジュール・namespaceは3点セット

```
フォルダ:     controllers/api/     ← ファイルの場所
モジュール:   module Api            ← コードのグループ名
ルーティング: namespace :api        ← URLのプレフィックス
```

この3つが一致して初めてRailsがコントローラーを正しく見つけられます。

---

## 第7章：Angular側の実装

### ① HttpClientを有効化

`frontend/src/app/app.config.ts`

```typescript
import { provideHttpClient } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient()   // これを追加
  ]
};
```

**HttpClient** はAngularがHTTPリクエスト（APIの呼び出し）を行うための機能です。
`providers` に登録することでアプリ全体で使えるようになります。

---

### ② コンポーネントでAPIを呼び出す

`frontend/src/app/app.ts`

```typescript
import { Component, signal, inject, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  private http = inject(HttpClient);       // HttpClientを使えるようにする
  message = signal('読み込み中...');       // 画面に表示する値

  ngOnInit() {                             // 画面表示時に自動実行される
    this.http.get<{ message: string }>('http://localhost:3000/api/hello')
      .subscribe({
        next: (data) => this.message.set(data.message),   // 成功時：値を更新
        error: () => this.message.set('接続に失敗しました') // 失敗時
      });
  }
}
```

**重要なキーワード：**

| キーワード | 意味 |
|-----------|------|
| `signal` | 画面と連動する変数。値が変わると画面も自動更新される |
| `inject(HttpClient)` | HttpClientを使えるようにする |
| `ngOnInit()` | コンポーネントが画面に表示されたときに自動で実行されるメソッド |
| `http.get<T>(url)` | GETリクエストを送る。`<T>` は受け取るデータの型 |
| `subscribe()` | 非同期処理の結果を受け取る |

#### 非同期処理とは

APIへのリクエストは「時間がかかる処理」です。
レスポンスを待っている間もブラウザは動き続けます。

```
APIを呼び出す → 待機中でも画面は操作できる → レスポンスが来たら値を更新
```

`subscribe()` はレスポンスが来たときに実行する処理を登録するものです。

---

### ③ HTMLに表示

`frontend/src/app/app.html`

```html
<main>
  <h1>{{ message() }}</h1>
</main>
```

`{{ message() }}` は **データバインディング** と呼ばれます。
`signal` の値を画面に表示する構文です。
`message` の値が変わると画面も自動的に更新されます。

---

## 第8章：データの流れ（まとめ）

```
1. ブラウザが localhost:4200 にアクセス
         ↓
2. Angularが起動、ngOnInit() が実行される
         ↓
3. HttpClient が localhost:3000/api/hello にGETリクエストを送る
         ↓
4. Railsのルーティングが受け取り Api::HelloController#index を実行
         ↓
5. Rails が { message: "こんにちは！..." } をJSONで返す
         ↓
6. subscribe() の next が実行され message.set() で値を更新
         ↓
7. {{ message() }} が更新され画面に「こんにちは！...」が表示される
```

---

## ファイル構成のまとめ

```
backend/
├── Gemfile                              ← 使うGemを宣言（rack-cors）
├── config/
│   ├── routes.rb                        ← URLとコントローラーの対応
│   └── initializers/cors.rb             ← CORSの許可設定
└── app/controllers/api/
    └── hello_controller.rb              ← リクエストを処理してJSONを返す

frontend/src/app/
├── app.config.ts                        ← HttpClientを有効化
├── app.ts                               ← APIを呼び出して値を保持
└── app.html                             ← 値を画面に表示
```
