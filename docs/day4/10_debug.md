# Day 4-③ 動作確認・よくあるエラー

## 全体の動作確認フロー

```
1. docker compose up でDB・Rails・Angular起動
2. http://localhost:4200/login を開く
3. サインアップしてアカウントを作る
4. /tasks でタスクを数件追加する
5. /focus でタスクが表示されるか確認
6. 「達成」「スキップ」を繰り返す
7. 全タスク消化後に /review に遷移するか確認
8. 「明日またがんばる」で /focus に戻るか確認
```

---

## よくあるエラーと対処

### Rails側

#### `401 Unauthorized` が返ってくる
JWTトークンが付いていないか、期限切れ。
- Angular側のインターセプターが正しく設定されているか確認
- `localStorage.getItem('token')` でトークンが保存されているか確認

```bash
# curlで確認するときはトークンを付ける
TOKEN="eyJ..."
curl http://localhost:3000/api/tasks \
  -H "Authorization: Bearer $TOKEN"
```

#### `JWT::DecodeError` が発生する
トークンが不正。`Rails.application.secret_key_base` が環境によって変わっている可能性がある。
開発環境では `config/credentials.yml.enc` で管理されている。

#### `NameError: uninitialized constant Api::AuthController`
コントローラーファイルがない or クラス名のスペルミス。
ファイルが `app/controllers/api/auth_controller.rb` にあるか確認。

#### `ActiveRecord::RecordInvalid`
バリデーションエラー。コンソールで確認：
```ruby
user = User.new(email: "test@test.com", password: "short")
user.valid?
user.errors.full_messages
```

#### `PG::UniqueViolation`
同じメールアドレスで2回サインアップしようとしている。
同じ `task_id + logged_on` の組み合わせが既に存在する。

#### マイグレーションを間違えたとき
```bash
docker compose exec web rails db:rollback
# マイグレーションファイルを修正してから
docker compose exec web rails db:migrate
```

---

### Angular側

#### `/login` にアクセスしても認証ガードが動かない
`app.routes.ts` に `canActivate: [authGuard]` が設定されているか確認。

#### ログイン後も `/login` に戻ってしまう
`AuthService.isLoggedIn()` が正しく動いているか確認：
```typescript
// ブラウザのコンソールで確認
localStorage.getItem('token')  // tokenがあれば文字列、なければnull
```

#### `NullInjectorError: No provider for HttpClient`
`app.config.ts` に `provideHttpClient(withInterceptors([authInterceptor]))` が追加されているか確認。

#### APIのレスポンスが見えない
`subscribe` にエラーハンドラを追加して確認：
```typescript
this.taskService.getTasks().subscribe({
  next: (tasks) => console.log(tasks),
  error: (err) => console.error(err)
});
```

#### CORSエラーがブラウザコンソールに出る
- Railsが起動しているか確認
- `config/initializers/cors.rb` が正しく設定されているか確認
- Railsを再起動（initializersは起動時に読み込まれる）

---

## デバッグに便利なコマンド

```bash
# Railsのログをリアルタイムで見る
docker compose logs -f web

# Railsコンソールで直接DBを操作
docker compose exec web rails console

# ルーティング一覧を確認
docker compose exec web rails routes | grep api

# マイグレーション状態を確認
docker compose exec web rails db:migrate:status

# トークンを手動で生成（デバッグ用）
docker compose exec web rails runner "
  user = User.first
  token = JWT.encode({ user_id: user.id, exp: 30.days.from_now.to_i }, Rails.application.secret_key_base)
  puts token
"
```

---

## ブラウザの開発者ツール

- **Network タブ** — APIリクエストの内容とレスポンスを確認できる。`Authorization` ヘッダーが付いているか確認。
- **Console タブ** — JavaScriptのエラーとCORSエラーが出る
- **Application タブ** — LocalStorage の `token` を確認できる

---

## 完成チェックリスト

### バックエンド
- [ ] `rails db:migrate` が成功している（schema.rb に全テーブルがある）
- [ ] `rails routes` でAPIルートが全部表示される
- [ ] curl でサインアップ・ログインできてトークンが返ってくる
- [ ] トークン付きでタスク追加・取得ができる
- [ ] CORS設定が済んでいる

### フロントエンド
- [ ] `/login` でサインアップ・ログインができる
- [ ] ログイン後 `/focus` に遷移する
- [ ] 未ログインで `/focus` にアクセスすると `/login` にリダイレクトされる
- [ ] `/tasks` でタスクの追加・削除・並び替えができる
- [ ] `/focus` でタスクが1件表示される
- [ ] 「達成」「スキップ」で次のタスクに変わる
- [ ] 「今日はここまで」で `/review` に遷移する
- [ ] `/review` で今日の達成数・スキップ数が表示される
- [ ] 「明日またがんばる」で `/focus` に戻る

---

## お疲れ様でした！

Hexopus 完成です。
