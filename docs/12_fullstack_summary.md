# 12 - フルスタック通信まとめ

[← 目次に戻る](./00_index.md)

---

## 全体フロー

```
[ユーザー操作]
     ↓
[Angular Component]  画面・イベント管理
     ↓
[Angular Service]    HTTP通信の窓口
     ↓  HttpClient
[HTTP リクエスト]    GET/POST/DELETE + JSON
     ↓
[Rails Router]       URLをコントローラに振り分け
     ↓
[Rails Controller]   ビジネスロジック
     ↓
[Rails Model]        DB操作
     ↓
[PostgreSQL]         データ永続化
     ↓ (逆順でレスポンス)
[render json:]       JSONに変換して返す
     ↓
[Angular Service]    レスポンス受け取り
     ↓
[Angular Component]  画面再描画
```

---

## 各層の役割

### Rails側

| 層 | ファイル | 役割 |
|----|---------|------|
| Router | `config/routes.rb` | URLとコントローラの対応 |
| Controller | `app/controllers/` | リクエスト処理・レスポンス生成 |
| Model | `app/models/` | DB操作・バリデーション |

```ruby
# routes.rb：URLの定義
namespace :api do
  resources :genres
end

# controller：処理して返す
def index
  render json: Genre.all
end
```

### Angular側

| 層 | ファイル | 役割 |
|----|---------|------|
| Service | `*.service.ts` | HTTP通信・データ取得 |
| Component | `*.ts` | 画面ロジック・状態管理 |
| Template | `*.html` | 画面表示 |

```typescript
// service：RailsのURLを叩く
const API_BASE = 'http://localhost:3000/api';
getAll(): Observable<Genre[]> {
  return this.http.get<Genre[]>(`${API_BASE}/genres`);
}

// component：serviceを使って画面更新
this.genreService.getAll().subscribe(genres => {
  this.genres.set(genres);
});
```

---

## HTTPメソッドとCRUDの対応

| 操作 | HTTPメソッド | Rails action | 例 |
|------|------------|-------------|-----|
| 一覧取得 | GET | `index` | `GET /api/genres` |
| 詳細取得 | GET | `show` | `GET /api/genres/1` |
| 作成 | POST | `create` | `POST /api/genres` |
| 更新 | PATCH/PUT | `update` | `PATCH /api/genres/1` |
| 削除 | DELETE | `destroy` | `DELETE /api/genres/1` |

---

## データの形式（JSON）

```
Angular → Rails：JSONで送信
{ "genre": { "name": "本" } }

Rails → Angular：JSONで返す
[{ "id": 1, "name": "本", "created_at": "..." }]
```

---

## このプロジェクトの具体的な対応表

```
Angular                          Rails
─────────────────────────────────────────────
genre.service.ts                 genres_controller.rb
  getAll()    GET /api/genres  →   index   → Genre.all
  create()   POST /api/genres  →   create  → Genre.create
  delete()  DELETE /api/genres →   destroy → genre.destroy
```

---

## キーワードまとめ

| 用語 | 意味 |
|------|------|
| REST API | URLとHTTPメソッドでリソース操作を表す設計 |
| HttpClient | AngularでHTTP通信するための標準ライブラリ |
| Observable | 非同期処理の結果を扱うRxJSの型（`.subscribe()`で受け取る） |
| render json: | RailsでオブジェクトをJSONに変換して返す |
| CORS | 異なるURL間（localhost:4200 → :3000）の通信を許可する設定 |

---

[← 目次に戻る](./00_index.md)
