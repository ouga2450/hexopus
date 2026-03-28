# Day 2-② コントローラー実装（JWT認証含む）

## コントローラーとは？

リクエストを受けて、Modelからデータを取り出し、JSONを返す役割。

```
リクエスト → ルーティング → コントローラー → モデル → JSON返却
```

---

## ファイルの置き場所

```
app/controllers/
└── api/
    ├── auth_controller.rb       # 認証（signup/login）
    ├── tasks_controller.rb
    ├── focus/
    │   ├── current_controller.rb
    │   └── log_controller.rb
    └── review/
        └── today_controller.rb
```

---

## JWT認証の仕組み

```
1. ユーザーがメール+パスワードでログイン
2. Railsがパスワードを検証し、JWTトークンを返す
3. AngularはトークンをlocalStorageに保存
4. 以降のリクエストには Authorization: Bearer <token> を付ける
5. Railsはトークンを検証してユーザーを特定する
```

---

## Gemの追加

```ruby
# Gemfile
gem "jwt"
```

```bash
bundle install
```

---

## ApplicationController（JWT検証）

すべてのコントローラーの親クラス。ここにJWT検証ロジックを書くと、全エンドポイントで認証が必要になる。

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = JWT.decode(token, Rails.application.secret_key_base).first
    @current_user = User.find(payload["user_id"])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: "認証が必要です" }, status: :unauthorized
  end

  def encode_token(user_id)
    exp = 30.days.from_now.to_i
    JWT.encode({ user_id: user_id, exp: exp }, Rails.application.secret_key_base)
  end
end
```

### ポイント解説

**`before_action :authenticate!`** — コントローラーのメソッドが呼ばれる前に必ず実行される。

**`request.headers["Authorization"]`** — リクエストヘッダーからトークンを取得。`Bearer eyJ...` という形式なので `split(" ").last` で本体だけ取り出す。

**`JWT.decode`** — トークンを解析してpayload（中身）を取り出す。署名が違う・期限切れの場合は `JWT::DecodeError` が発生する。

---

## Api::AuthController

```ruby
# app/controllers/api/auth_controller.rb
class Api::AuthController < ApplicationController
  skip_before_action :authenticate!  # signup/login は認証不要

  # POST /api/auth/signup
  def signup
    user = User.new(signup_params)
    if user.save
      token = encode_token(user.id)
      render json: { token: token, user: user_json(user) }, status: :created
    else
      render json: { error: user.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  # POST /api/auth/login
  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = encode_token(user.id)
      render json: { token: token, user: user_json(user) }
    else
      render json: { error: "メールアドレスまたはパスワードが違います" }, status: :unauthorized
    end
  end

  private

  def signup_params
    params.permit(:name, :email, :password)
  end

  def user_json(user)
    { id: user.id, name: user.name, email: user.email }
  end
end
```

### ポイント解説

**`skip_before_action :authenticate!`** — 親クラスの `before_action` をこのコントローラーだけスキップする。

**`user&.authenticate`** — `&.` はnilセーフ演算子。`user` が `nil`（ユーザーが見つからない）のときでもエラーにならない。

---

## Api::TasksController

```ruby
# app/controllers/api/tasks_controller.rb
class Api::TasksController < ApplicationController

  # GET /api/tasks
  def index
    tasks = Task.order(:priority)
    render json: tasks
  end

  # POST /api/tasks
  def create
    task = Task.new(task_params)
    task.priority = Task.count + 1

    if task.save
      render json: task, status: :created
    else
      render json: { error: task.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  # PATCH /api/tasks/reorder
  def reorder
    params[:order].each_with_index do |task_id, index|
      Task.where(id: task_id).update_all(priority: index + 1)
    end
    render json: { ok: true }
  end

  # DELETE /api/tasks/:id
  def destroy
    Task.find(params[:id]).destroy
    head :no_content
  end

  private

  def task_params
    params.require(:task).permit(:title)
  end
end
```

---

## Api::Focus::CurrentController

```ruby
# app/controllers/api/focus/current_controller.rb
class Api::Focus::CurrentController < ApplicationController

  # GET /api/focus/current
  def index
    logged_ids = DailyLog.where(logged_on: Date.today).pluck(:task_id)
    task = Task.where.not(id: logged_ids).order(:priority).first

    if task
      render json: task
    else
      render json: { current: nil }
    end
  end
end
```

**`pluck(:task_id)`** — 指定したカラムの値だけを配列で取得する。

**`where.not(id: logged_ids)`** — `NOT IN` のSQL。「含まれないもの」を取得。

---

## Api::Focus::LogController

```ruby
# app/controllers/api/focus/log_controller.rb
class Api::Focus::LogController < ApplicationController

  # POST /api/focus/log
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
  def index
    logs  = DailyLog.where(logged_on: Date.today)
    total = Task.count

    render json: {
      done:      logs.where(status: "done").count,
      skip:      logs.where(status: "skip").count,
      remaining: total - logs.count,
      total:     total
    }
  end
end
```

---

## 動作確認（curlで叩く）

```bash
# ユーザー登録
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"太郎","email":"taro@example.com","password":"password123"}'

# ログイン → tokenを取得
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"taro@example.com","password":"password123"}'

# 取得したtokenをセットしてタスク一覧を取得
TOKEN="eyJ..."
curl http://localhost:3000/api/tasks \
  -H "Authorization: Bearer $TOKEN"
```

---

## 次のステップ

→ [05_cors.md](05_cors.md) でAngularからアクセスできるようにする
