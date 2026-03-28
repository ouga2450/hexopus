# Day 4-③ 動作確認・よくあるエラー

## 全体の動作確認フロー

```
1. docker compose up でDB・Rails起動
2. cd frontend && ng serve でAngular起動
3. http://localhost:4200/tasks を開く
4. タスクを数件追加する
5. /focus でタスクが表示されるか確認
6. 「達成」「スキップ」を繰り返す
7. 全タスク消化後に /review に遷移するか確認
```

---

## よくあるエラーと対処

### Rails側

#### `NameError: uninitialized constant Api::TasksController`
コントローラーファイルがない or クラス名のスペルミス。
- ファイルが `app/controllers/api/tasks_controller.rb` にあるか確認
- クラス名が `class Api::TasksController` になっているか確認

#### `ActiveRecord::RecordInvalid`
バリデーションエラー。コンソールで確認：
```ruby
task = Task.new(title: nil)
task.valid?        # false
task.errors.full_messages  # ["Title can't be blank"]
```

#### `PG::UniqueViolation`
同じ `task_id + logged_on` の組み合わせが既に存在する。
今日すでにそのタスクにログが入っている。

#### マイグレーションを間違えたとき
```bash
rails db:rollback    # 直前のマイグレーションを元に戻す
# マイグレーションファイルを修正してから
rails db:migrate
```

---

### Angular側

#### `NullInjectorError: No provider for HttpClient`
`app.config.ts` に `provideHttpClient()` が追加されているか確認。

#### `Can't bind to 'ngModel' since it isn't a known property`
`FormsModule` を `imports` に追加していない。

#### APIエラーが握り潰されている
`subscribe` にエラーハンドラを追加して確認：
```typescript
this.taskService.getTasks().subscribe({
  next: (tasks) => console.log(tasks),
  error: (err) => console.error(err)
});
```

#### CORSエラーがブラウザコンソールに出る
- Rails が起動しているか確認（`docker compose up`）
- `config/initializers/cors.rb` が正しく設定されているか確認
- Rails を再起動したか確認（initializers は起動時に読み込まれる）

---

## デバッグに便利なコマンド

```bash
# Railsのログをリアルタイムで見る
docker compose logs -f backend

# Railsコンソールで直接DBを操作
docker compose exec backend rails console

# ルーティング一覧を確認
docker compose exec backend rails routes | grep api

# マイグレーション状態を確認
docker compose exec backend rails db:migrate:status
```

---

## ブラウザの開発者ツール

- **Network タブ** — APIリクエストの内容とレスポンスを確認できる
- **Console タブ** — JavaScriptのエラーとCORSエラーが出る

---

## 完成チェックリスト

### バックエンド
- [ ] `rails db:migrate` が成功している（schema.rb にテーブルがある）
- [ ] `rails routes` でAPIルートが全部表示される
- [ ] curl でタスク追加・取得ができる
- [ ] CORS設定が済んでいる

### フロントエンド
- [ ] `/tasks` でタスクの追加・削除ができる
- [ ] `/focus` でタスクが1件表示される
- [ ] 「達成」「スキップ」で次のタスクに変わる
- [ ] 「今日はここまで」で `/review` に遷移する
- [ ] `/review` で今日の達成数・スキップ数が表示される
- [ ] 「明日またがんばる」で `/focus` に戻る

---

## お疲れ様でした！

Hexopus 完成です。
