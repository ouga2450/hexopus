# Day 2-② コントローラー実装

## コントローラーとは？

リクエストを受けて、Modelからデータを取り出し、JSONを返す役割。

```
リクエスト → ルーティング → コントローラー → モデル → JSON返却
```

---

## ファイルの置き場所

`namespace :api` の下にあるので、ディレクトリも対応して作る：

```
app/controllers/
└── api/
    ├── tasks_controller.rb
    ├── focus/
    │   ├── current_controller.rb
    │   └── log_controller.rb
    └── review/
        └── today_controller.rb
```

---

## Api::TasksController

```ruby
# app/controllers/api/tasks_controller.rb
class Api::TasksController < ApplicationController

  # GET /api/tasks
  # タスク一覧をpriority昇順で返す
  def index
    tasks = Task.order(:priority)
    render json: tasks
  end

  # POST /api/tasks
  # タスクを追加する（6件上限）
  def create
    task = Task.new(task_params)
    task.priority = Task.count + 1  # 末尾に追加

    if task.save
      render json: task, status: :created
    else
      render json: { error: task.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  # PATCH /api/tasks/reorder
  # 優先順位を一括更新する
  def reorder
    order = params[:order]  # [5, 2, 8, 1, 4, 3] のようなtask idの配列

    order.each_with_index do |task_id, index|
      Task.where(id: task_id).update_all(priority: index + 1)
    end

    render json: { ok: true }
  end

  # DELETE /api/tasks/:id
  # タスクを削除する
  def destroy
    task = Task.find(params[:id])
    task.destroy
    head :no_content  # 204 No Content（ボディなし）
  end

  private

  # 許可するパラメーターを絞る（セキュリティ）
  def task_params
    params.require(:task).permit(:title)
  end
end
```

### ポイント解説

**`render json:`** — ハッシュや ActiveRecord オブジェクトを JSON に変換して返す。

**`status: :created`** — HTTPステータス201を返す。作成成功のシグナル。

**`status: :unprocessable_entity`** — ステータス422。バリデーションエラー時。

**`head :no_content`** — ボディなしでステータス204だけ返す。DELETE成功時の慣習。

**`params.require(:task).permit(:title)`** — 許可したパラメーターだけ受け取る（Strong Parameters）。

---

## Api::Focus::CurrentController

```ruby
# app/controllers/api/focus/current_controller.rb
class Api::Focus::CurrentController < ApplicationController

  # GET /api/focus/current
  # 今日まだ処理していない最優先タスクを1件返す
  def index
    # 今日すでにログがあるtask_idを取得
    logged_ids = DailyLog.where(logged_on: Date.today).pluck(:task_id)

    # ログがないタスクの中で一番priorityが小さいものを取得
    task = Task.where.not(id: logged_ids).order(:priority).first

    if task
      render json: task
    else
      render json: { current: nil }
    end
  end
end
```

### ポイント解説

**`pluck(:task_id)`** — 指定したカラムの値だけを配列で取得する。SQLを最小限にする。

**`where.not(id: logged_ids)`** — `NOT IN` のSQL。「含まれないもの」を取得。

---

## Api::Focus::LogController

```ruby
# app/controllers/api/focus/log_controller.rb
class Api::Focus::LogController < ApplicationController

  # POST /api/focus/log
  # done または skip を記録する
  def create
    log = DailyLog.new(
      task_id: params[:task_id],
      status: params[:status],
      logged_on: Date.today
    )

    if log.save
      render json: { logged_on: log.logged_on, status: log.status }
    else
      render json: { error: log.errors.full_messages.first }, status: :unprocessable_entity
    end
  end
end
```

---

## Api::Review::TodayController

```ruby
# app/controllers/api/review/today_controller.rb
class Api::Review::TodayController < ApplicationController

  # GET /api/review/today
  # 今日の達成数・スキップ数・残数を返す
  def index
    logs = DailyLog.where(logged_on: Date.today)

    done  = logs.where(status: "done").count
    skip  = logs.where(status: "skip").count
    total = Task.count
    remaining = total - logs.count

    render json: {
      done: done,
      skip: skip,
      remaining: remaining,
      total: total
    }
  end
end
```

---

## 動作確認（curlで叩く）

```bash
# タスク一覧
curl http://localhost:3000/api/tasks

# タスク追加
curl -X POST http://localhost:3000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"task": {"title": "Rails学習"}}'

# フォーカス中のタスク取得
curl http://localhost:3000/api/focus/current

# done を記録
curl -X POST http://localhost:3000/api/focus/log \
  -H "Content-Type: application/json" \
  -d '{"task_id": 1, "status": "done"}'

# 今日の振り返り
curl http://localhost:3000/api/review/today
```

---

## 次のステップ

→ [05_cors.md](05_cors.md) でAngularからアクセスできるようにする
