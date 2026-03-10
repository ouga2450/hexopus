# 06 - Railsのコントローラー

[← 目次に戻る](./00_index.md)

---

## コントローラーとは

リクエストを受け取ってレスポンスを返す役割を持ちます。
Rails APIではHTMLではなくJSONを返します。

---

## モジュールとは

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

`Api::HelloController` と書くことで「ApiグループのHelloController」という意味になります。
他のグループの同名クラスと区別できます。

### フォルダ・モジュール・namespaceは3点セット

```
フォルダ:     controllers/api/     ← ファイルの場所
モジュール:   module Api            ← コードのグループ名
ルーティング: namespace :api        ← URLのプレフィックス
```

この3つが一致して初めてRailsがコントローラーを正しく見つけられます。

---

## JSONを返す

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

| コード | 意味 |
|--------|------|
| `module Api` | api/ フォルダに対応するグループ名 |
| `class HelloController` | コントローラーの名前 |
| `< ApplicationController` | 基本機能を継承する |
| `def index` | GETリクエストに対する処理 |
| `render json: { ... }` | JSONを返す |

---

[次へ → 07 - AngularのHttpClient](./07_angular_httpclient.md)
