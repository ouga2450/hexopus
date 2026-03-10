# Zennly — CLAUDE.md

このファイルはClaude Codeが本プロジェクトを理解するための引き継ぎドキュメントです。
コーディングを始める前に必ずこのファイルを読んでください。

---

## プロジェクト概要

**Zennly（ゼンリー）** は「大きな夢を、今日の一歩に。」をコンセプトにした目標逆算アプリです。

ユーザーが10年後・5年後・1年後・今月・今週・今日の目標を設定すると、
AIが上位目標から逆算して下位目標の候補を提案します。
毎日の振り返り（日記）と組み合わせることで、長期目標と日々の行動を繋ぎます。

### コアコンセプト

- **目標の階層構造**: 10年 → 5年 → 1年 → 今月 → 今週 → 今日 の6階層
- **AI逆算提案**: 上位目標をコンテキストにAnthropicのClaudeが下位目標を提案
- **複数選択**: 各階層で複数の目標を選択・追加できる
- **禅的UX**: シンプルで余白のある、内省を促すデザイン

---

## 技術スタック

| レイヤー | 技術 | 備考 |
|---|---|---|
| フロントエンド | Angular | TypeScript, SCSS |
| バックエンド | Rails 7 (API mode) | Ruby, ActiveRecord |
| DB | PostgreSQL | |
| AI | Anthropic API (Claude) | バックエンド経由で呼ぶ（APIキーをフロントに渡さない） |
| 起動 | Docker Compose | `docker compose up` |
| デプロイ | Render → 将来AWS | |

### ローカル起動

```bash
docker compose up
```

- フロントエンド: http://localhost:4200
- バックエンド: http://localhost:3000

---

## ディレクトリ構成

```
zennly/
├── frontend/          # Angular アプリ
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/          # 認証・APIサービス・ガード
│   │   │   ├── features/
│   │   │   │   ├── goals/     # 目標管理（階層設定）
│   │   │   │   ├── today/     # 今日のタスク・AI提案
│   │   │   │   └── journal/   # 日記・振り返り
│   │   │   └── shared/        # 共通コンポーネント
│   │   └── environments/
│   └── ...
├── backend/           # Rails API
│   ├── app/
│   │   ├── controllers/
│   │   │   └── api/v1/
│   │   │       ├── goals_controller.rb
│   │   │       ├── ai_suggestions_controller.rb
│   │   │       └── journal_entries_controller.rb
│   │   ├── models/
│   │   │   ├── user.rb
│   │   │   ├── goal.rb
│   │   │   └── journal_entry.rb
│   │   └── services/
│   │       └── anthropic_service.rb   # AI呼び出しロジック
│   ├── config/
│   │   └── routes.rb
│   └── ...
├── docs/              # 設計ドキュメント
├── compose.yml
├── CLAUDE.md          # このファイル
└── README.md
```

---

## データモデル

### User

```ruby
# 認証はDevise + JWT
t.string  :email, null: false, unique: true
t.string  :encrypted_password
t.string  :name
t.timestamps
```

### Goal（目標）

```ruby
t.references :user, null: false, foreign_key: true
t.string  :level, null: false   # "y10" | "y5" | "y1" | "mon" | "week" | "day"
t.string  :content, null: false # 目標テキスト
t.integer :position             # 同一levelで複数ある場合の順序
t.date    :target_date          # 対象日（dayレベルは日付、weekは週開始日等）
t.boolean :active, default: true
t.timestamps
```

**levelの定義:**
- `y10` : 10年後のビジョン
- `y5`  : 5年後のマイルストーン
- `y1`  : 1年後の目標
- `mon` : 今月のフォーカス
- `week`: 今週のタスク
- `day` : 今日やること

### JournalEntry（日記）

```ruby
t.references :user, null: false, foreign_key: true
t.date    :date, null: false
t.text    :reflection           # 振り返りテキスト
t.integer :mood                 # 0〜4 (🌱☀️🌊🍂⛩️)
t.integer :score                # 1〜5 その日の達成度
t.json    :completed_goals      # 完了したgoal IDの配列
t.timestamps
```

---

## APIエンドポイント設計

```
# 認証
POST   /api/v1/auth/sign_up
POST   /api/v1/auth/sign_in
DELETE /api/v1/auth/sign_out

# 目標
GET    /api/v1/goals              # 全レベルの目標一覧（current user）
POST   /api/v1/goals              # 目標の作成
PUT    /api/v1/goals/:id          # 目標の更新
DELETE /api/v1/goals/:id          # 目標の削除

# AI提案
POST   /api/v1/ai_suggestions     # 上位目標を渡してAIに次の階層を提案させる
# body: { level: "y5", context: { y10: ["..."], y5: [], ... } }

# 日記
GET    /api/v1/journal_entries    # 一覧（直近30日）
POST   /api/v1/journal_entries    # 作成・更新（同日付はupsert）
GET    /api/v1/journal_entries/:date  # 特定日の取得
```

---

## AI連携（重要）

**APIキーは必ずバックエンドで管理する。フロントエンドに漏らさない。**

### AnthropicService（バックエンド）

```ruby
# backend/app/services/anthropic_service.rb

class AnthropicService
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL   = "claude-sonnet-4-20250514"

  def self.suggest_goals(level:, context:)
    level_info = LEVELS[level]
    ctx_text = context
      .select { |k, v| LEVELS[k][:depth] < level_info[:depth] && v.any? }
      .map { |k, v| "【#{LEVELS[k][:label]}】#{v.join('、')}" }
      .join("\n")

    system_prompt = <<~PROMPT
      あなたは人生設計のコーチです。
      上位目標から逆算して、次の階層の具体的な目標・タスクを提案します。
      必ずJSON形式のみで返答。前置き・説明文は一切不要。
      形式: {"items": ["目標1", "目標2", "目標3"], "hint": "この段階のポイントを一言（20字以内）"}
      itemsは3つ。具体的で実行可能な内容にする。
    PROMPT

    user_message = "上位目標:\n#{ctx_text.presence || '（未設定）'}\n\n次に「#{level_info[:label]}（#{level_info[:sub]}）」の具体的な目標を3つ提案してください。"

    response = HTTP.headers(
      "Content-Type"      => "application/json",
      "x-api-key"         => ENV["ANTHROPIC_API_KEY"],
      "anthropic-version" => "2023-06-01"
    ).post(API_URL, json: {
      model: MODEL,
      max_tokens: 500,
      system: system_prompt,
      messages: [{ role: "user", content: user_message }]
    })

    parsed = JSON.parse(response.body)
    JSON.parse(parsed.dig("content", 0, "text"))
  rescue => e
    Rails.logger.error("AnthropicService error: #{e.message}")
    { "items" => [], "hint" => "" }
  end

  LEVELS = {
    "y10"  => { label: "10年後", sub: "人生のビジョン",       depth: 0 },
    "y5"   => { label: "5年後",  sub: "中期マイルストーン",   depth: 1 },
    "y1"   => { label: "1年後",  sub: "今年の目標",           depth: 2 },
    "mon"  => { label: "今月",   sub: "月間フォーカス",       depth: 3 },
    "week" => { label: "今週",   sub: "週間タスク",           depth: 4 },
    "day"  => { label: "今日",   sub: "今日やること",         depth: 5 },
  }.freeze
end
```

### AI提案コントローラー

```ruby
# POST /api/v1/ai_suggestions
# body: { level: "y5", context: { y10: ["..."], y5: [], ... } }
def create
  result = AnthropicService.suggest_goals(
    level:   params[:level],
    context: params[:context].to_h
  )
  render json: result
end
```

---

## Angular フロント実装方針

### モジュール構成（Standalone Components推奨）

```
GoalsComponent      # 階層ごとの目標マップ表示・編集
TodayComponent      # 今日のタスク・AI提案表示
JournalComponent    # 日記入力・振り返り
GoalCardComponent   # 各階層カード（トグル選択・追加対応）
```

### GoalsService（目標状態管理）

```typescript
// goals[level] は string[] （複数選択可）
interface GoalState {
  y10:  string[];
  y5:   string[];
  y1:   string[];
  mon:  string[];
  week: string[];
  day:  string[];
}
```

### AI提案の呼び出し

フロントからは `/api/v1/ai_suggestions` にPOSTするだけ。
Anthropic APIキーはバックエンドの環境変数として管理。

```typescript
// frontend/src/app/core/services/ai.service.ts
suggestGoals(level: string, context: GoalState): Observable<AiSuggestion> {
  return this.http.post<AiSuggestion>('/api/v1/ai_suggestions', { level, context });
}
```

---

## 環境変数

### バックエンド（.env）

```
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_URL=postgresql://...
SECRET_KEY_BASE=...
FRONTEND_ORIGIN=http://localhost:4200
```

### フロントエンド（environment.ts）

```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3000',
};
```

---

## 開発の優先順位

### フェーズ1：コア機能（MVP）

1. Rails: User, Goal モデル + 認証（Devise + JWT）
2. Rails: Goals CRUD API
3. Rails: AnthropicService + `/api/v1/ai_suggestions`
4. Angular: 目標マップ画面（6階層のカード表示・入力）
5. Angular: AI提案の取得・トグル選択
6. Angular: 今日のタスク画面

### フェーズ2：日記・振り返り

7. Rails: JournalEntry モデル + API
8. Angular: 日記入力・振り返り画面
9. Angular: 過去の記録一覧

### フェーズ3：品質・デプロイ

10. 認証ガード・エラーハンドリング
11. Render デプロイ設定
12. （将来）AWS移行

---

## コーディング規約

### Rails

- コントローラーはスリムに。ロジックはServiceに切り出す
- APIレスポンスはsnake_caseで統一
- エラーは `render json: { error: "..." }, status: :unprocessable_entity`

### Angular

- Standalone Componentsを使う（NgModuleは作らない）
- 状態管理はServiceのBehaviorSubjectで行う（NgRxは使わない）
- テンプレートはシンプルに。複雑なロジックはComponentクラスに置く
- CSSはSCSSで書く。グローバルスタイルは `styles.scss` のみ

### 共通

- コミットメッセージは日本語OK
- ブランチ名: `feature/goal-api`, `fix/ai-suggestion-error` など

---

## デザイン・UXの方針

- **禅的ミニマリズム**: 余白を大切に。詰め込まない
- **カラーパレット**: 深海ブルー系（#050d1a ベース、#42a8e8 アクセント）
- **インタラクション**: 提案カードはタップでトグル（追加/解除）。消えない
- **モバイルファースト**: max-width 480px を基準に設計

---

## よくある質問

**Q: Angularのバージョンは？**
A: Angular 17以降（Standalone Components対応）を想定。

**Q: 認証方式は？**
A: Devise + devise-jwt。JWTをAuthorizationヘッダで受け渡す。

**Q: CORSの設定は？**
A: `rack-cors` を使用。`FRONTEND_ORIGIN` 環境変数で許可オリジンを制御。

**Q: AI提案のレート制限は？**
A: Anthropic APIのレートリミットに従う。フロントからは連打されないようボタンをdisabledにする。
