# 10 - データの流れ全体像

[← 目次に戻る](./00_index.md)

---

## リクエストからレスポンスまでの流れ

```
1. ブラウザが localhost:4200 にアクセス
         ↓
2. Angularが起動、ngOnInit() が実行される
         ↓
3. HttpClient が localhost:3000/api/hello にGETリクエストを送る
         ↓
4. Railsのルーティングが受け取る
   GET /api/hello → Api::HelloController#index を実行
         ↓
5. Rails が JSON を返す
   { message: "こんにちは！FocusFlowへようこそ" }
         ↓
6. subscribe() の next が実行される
   message.set(data.message) で値を更新
         ↓
7. {{ message() }} が更新され画面に表示される
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

---

## 各ファイルの役割まとめ

| ファイル | 役割 | 対応する概念 |
|---------|------|------------|
| `Gemfile` | 使うライブラリを宣言 | - |
| `cors.rb` | どこからのアクセスを許可するか | CORS |
| `routes.rb` | URLとコントローラーの対応 | ルーティング |
| `hello_controller.rb` | リクエストを処理してJSONを返す | Controller |
| `app.config.ts` | Angularの機能を有効化 | providers |
| `app.ts` | APIを呼び出してデータを保持 | Component |
| `app.html` | データを画面に表示 | Template |

---

[← 目次に戻る](./00_index.md)
