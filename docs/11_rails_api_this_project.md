# このプロジェクトのRails API：サルでもわかる解説

---

## そもそも何をしているのか

このプロジェクトのRailsは**HTMLを返さない**。
ブラウザに表示する画面はAngularが作る。RailsはAngularに**データだけ渡す係**。

```
ブラウザ（Angular）  ←→  Rails  ←→  データベース
         画面を作る        データを渡す   データを保存する
```

データのやりとりには**JSON**という形式を使う。

```json
// JSONの例（「カメラ」というジャンルのデータ）
{ "id": 1, "name": "カメラ", "created_at": "2026-02-27T00:00:00Z" }
```

---

## ① データベースの設計図：マイグレーション

**ファイル：** `backend/db/migrate/20260227000001_create_genres.rb`

```ruby
create_table :genres do |t|
  t.string :name, null: false   # 名前（必須）
  t.timestamps                  # 作成日時・更新日時（自動）
end
```

**ファイル：** `backend/db/migrate/20260227000002_create_items.rb`

```ruby
create_table :items do |t|
  t.references :genre, null: false, foreign_key: true  # どのジャンルか
  t.string :name, null: false   # 商品名（必須）
  t.string :url                 # URL（任意）
  t.string :image_url           # 画像URL（任意）
  t.text :reason                # 欲しい理由（任意）
  t.timestamps
end
```

マイグレーションは「データベースにこういうテーブルを作ってください」という**設計図**。
`docker compose up` のときに `db:prepare` が実行されて、この設計図通りにテーブルが作られた。

### テーブルのイメージ

**genresテーブル**
| id | name | created_at |
|---|---|---|
| 1 | カメラ | 2026-02-27 |
| 2 | ヘッドホン | 2026-02-27 |

**itemsテーブル**
| id | genre_id | name | url | image_url | reason |
|---|---|---|---|---|---|
| 1 | 1 | Sony α7C II | https://... | https://... | 軽くて高画質 |
| 2 | 1 | Canon R8 | https://... | null | 安い |

`genre_id` という列が「このアイテムはどのジャンルに属するか」を示している。

---

## ② モデル：データベースとRubyをつなぐ

**ファイル：** `backend/app/models/genre.rb`

```ruby
class Genre < ApplicationRecord
  has_many :items, dependent: :destroy
  validates :name, presence: true
end
```

**ファイル：** `backend/app/models/item.rb`

```ruby
class Item < ApplicationRecord
  belongs_to :genre
  validates :name, presence: true
end
```

モデルはデータベースのテーブルとRubyのコードをつなぐ**橋渡し役**。

### has_many と belongs_to

```
Genre（ジャンル）  1対多  Item（アイテム）
   カメラ  ──────────  Sony α7C II
                  └──  Canon R8
```

- `has_many :items` → 「ジャンルはたくさんのアイテムを持てる」
- `belongs_to :genre` → 「アイテムはどこか1つのジャンルに属する」

### dependent: :destroy とは

```ruby
has_many :items, dependent: :destroy
```

「カメラ」というジャンルを削除したとき、カメラに紐づくアイテムも**自動で全部削除**される。
これがないと、どのジャンルにも属さないアイテムがDBに残ってしまう。

### validates とは

```ruby
validates :name, presence: true
```

`name` が空のままDBに保存しようとすると**エラーを出す**という宣言。
コントローラで `genre.save` が `false` を返す原因になる（後述）。

---

## ③ ルーティング：URLとコントローラを対応させる

**ファイル：** `backend/config/routes.rb`

```ruby
Rails.application.routes.draw do
  namespace :api do
    resources :genres, only: [:index, :create, :destroy] do
      resources :items, only: [:index, :create]
    end
    resources :items, only: [:destroy]
  end
end
```

このファイルが「どのURLにアクセスしたら、どのコントローラのどのメソッドを動かすか」を決めている。

### namespace :api とは

```ruby
namespace :api do
  ...
end
```

URLの先頭に `/api` をつける。`Api::` というモジュール名にもなる。
「これはAPIです」と明示するための慣習。

### resources とは

`resources :genres` と書くだけで、以下のURLが自動で作られる（`only:` で絞っている）：

| HTTPメソッド | URL | コントローラ#メソッド | 意味 |
|---|---|---|---|
| GET | `/api/genres` | `api/genres#index` | 一覧取得 |
| POST | `/api/genres` | `api/genres#create` | 新規作成 |
| DELETE | `/api/genres/:id` | `api/genres#destroy` | 削除 |

### ネストとは

```ruby
resources :genres do
  resources :items, only: [:index, :create]
end
```

「ジャンルの中にアイテムがある」という階層を表現している。

| HTTPメソッド | URL | 意味 |
|---|---|---|
| GET | `/api/genres/1/items` | ジャンル1のアイテム一覧 |
| POST | `/api/genres/1/items` | ジャンル1にアイテム追加 |

URLに `genres/1` が含まれることで「どのジャンルのアイテムか」が分かる。

---

## ④ コントローラ：リクエストを受けて処理する

### GenresController

**ファイル：** `backend/app/controllers/api/genres_controller.rb`

```ruby
module Api
  class GenresController < ApplicationController

    # GET /api/genres
    def index
      genres = Genre.all.order(:created_at)
      render json: genres
    end
```

`Genre.all` でDBのgenresテーブルの全行を取得。
`order(:created_at)` で古い順に並べる。
`render json: genres` でそれをJSONに変換してAngularに返す。

返るJSONのイメージ：
```json
[
  { "id": 1, "name": "カメラ", "created_at": "..." },
  { "id": 2, "name": "ヘッドホン", "created_at": "..." }
]
```

---

```ruby
    # POST /api/genres
    def create
      genre = Genre.new(genre_params)
      if genre.save
        render json: genre, status: :created
      else
        render json: { errors: genre.errors.full_messages }, status: :unprocessable_entity
      end
    end
```

`Genre.new(genre_params)` でジャンルオブジェクトを作る（まだDBには入っていない）。
`genre.save` でDBに保存する。成功したら `true`、失敗したら `false` を返す。

- 成功時 → 作成したジャンルをJSONで返す。`status: :created` はHTTPステータス201（作成完了）
- 失敗時 → エラーメッセージをJSONで返す。ステータス422（処理不可）

---

```ruby
    # DELETE /api/genres/:id
    def destroy
      genre = Genre.find(params[:id])
      genre.destroy
      head :no_content
    end
```

`params[:id]` はURLの `:id` 部分。`DELETE /api/genres/3` なら `params[:id]` は `"3"`。
`Genre.find(3)` でDBからid=3のジャンルを取得。
`genre.destroy` で削除（モデルに `dependent: :destroy` があるのでアイテムも連鎖削除）。
`head :no_content` はボディなしのレスポンス（ステータス204）。削除後は返すデータがないので。

---

```ruby
    private

    def genre_params
      params.require(:genre).permit(:name)
    end
```

Angularから送られてくるデータの形：
```json
{ "genre": { "name": "カメラ" } }
```

`params.require(:genre)` で `genre` キーの中身だけ取り出す。
`permit(:name)` で `name` だけ許可する（セキュリティ対策）。
これを**ストロングパラメータ**という。許可していないキーは無視される。

---

### ItemsController

**ファイル：** `backend/app/controllers/api/items_controller.rb`

```ruby
    # GET /api/genres/:genre_id/items
    def index
      genre = Genre.find(params[:genre_id])
      render json: genre.items.order(:created_at)
    end
```

URLが `/api/genres/1/items` なら `params[:genre_id]` は `"1"`。
`Genre.find(1)` でジャンルを取得。
`genre.items` は `has_many :items` のおかげで使える。「このジャンルに紐づくアイテム全部」を返す。
SQLに変換すると `SELECT * FROM items WHERE genre_id = 1 ORDER BY created_at` になる。

---

```ruby
    # POST /api/genres/:genre_id/items
    def create
      genre = Genre.find(params[:genre_id])
      item = genre.items.new(item_params)
      if item.save
        render json: item, status: :created
      else
        render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
      end
    end
```

`genre.items.new(item_params)` で作ると、`genre_id` が自動でセットされる。
自分で `item.genre_id = 1` と書かなくていい。

---

## ⑤ 全体の流れをひとつのシナリオで追う

**「カメラを追加する」ときの流れ**

```
① Angular が POST /api/genres に { genre: { name: "カメラ" } } を送る

② routes.rb が「これは genres#create だ」と判断

③ GenresController の create メソッドが動く

④ genre_params で { name: "カメラ" } だけ取り出す

⑤ Genre.new({ name: "カメラ" }) でオブジェクトを作る

⑥ genre.save でDBに INSERT される
   → genresテーブルに { id: 1, name: "カメラ" } が追加される

⑦ render json: genre で { "id": 1, "name": "カメラ", ... } をAngularに返す

⑧ Angular が受け取って画面に表示する
```

---

## まとめ：各ファイルの役割

| ファイル | 役割 | 一言で |
|---|---|---|
| `migrate/..._create_genres.rb` | テーブル設計図 | DBの形を決める |
| `models/genre.rb` | データの定義 | テーブルとRubyをつなぐ |
| `config/routes.rb` | URL対応表 | どのURLをどこに渡すか |
| `controllers/api/genres_controller.rb` | 処理の実装 | リクエストを処理してJSONを返す |

この4種類のファイルの組み合わせでRails APIは動いている。
