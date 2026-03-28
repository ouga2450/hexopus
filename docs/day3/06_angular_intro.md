# Day 3-① Angularとは・基本構造

## Angularとは？

Googleが作ったフロントエンドフレームワーク。HTMLとTypeScript（JavaScriptの上位互換）でUIを作る。

**コンポーネント**という単位で画面を分割して作るのが基本。

---

## 今回のフロントエンド構成

```
frontend/src/app/
├── app.ts               # ルートコンポーネント（全体の土台）
├── app.html             # ルートのHTML
├── app.routes.ts        # URLと画面の対応表
├── app.config.ts        # アプリ全体の設定（interceptorもここ）
└── components/          # 各画面
    ├── login/           # ログイン・サインアップ画面
    ├── focus/           # フォーカス画面（メイン）
    ├── review/          # 振り返り画面
    └── tasks/           # タスク管理画面
```

---

## コンポーネントとは？

HTML + TypeScript + CSS をひとまとめにした「部品」。

```typescript
// app/components/focus/focus.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-focus',       // HTMLで <app-focus /> と使える
  templateUrl: './focus.html',
  styleUrl: './focus.scss'
})
export class FocusComponent {
  // ここにTypeScriptのロジックを書く
}
```

---

## Signalsとは？（状態管理）

Angularの新しいリアクティブな変数。値が変わると自動でHTMLが更新される。

```typescript
import { signal } from '@angular/core';

currentTask = signal<string | null>(null);  // 初期値null

// 値を読む
console.log(this.currentTask());  // () をつけて呼び出す

// 値を変える
this.currentTask.set('Rails学習');
```

---

## HTMLの書き方（テンプレート構文）

```html
<!-- 条件分岐 -->
@if (currentTask()) {
  <p>{{ currentTask() }}</p>
} @else {
  <p>全タスク完了！</p>
}

<!-- ループ -->
@for (task of tasks(); track task.id) {
  <li>{{ task.title }}</li>
}
```

**`{{ }}`** = 変数をHTMLに埋め込む（補間）。

---

## コンポーネントの生成コマンド

```bash
cd frontend

ng g c components/login
ng g c components/focus
ng g c components/review
ng g c components/tasks
```

実行するとファイルが4つ生成される：
```
components/focus/
├── focus.ts
├── focus.html
├── focus.scss
└── focus.spec.ts  # テストファイル（今回は使わない）
```

---

## Standalone Componentとは？

最新のAngularでは `NgModule` が不要。コンポーネント単体で動く。
使いたい部品は `imports` に直接書く。

```typescript
@Component({
  selector: 'app-focus',
  imports: [RouterLink],  // ← 使うものをここに書く
  templateUrl: './focus.html',
  styleUrl: './focus.scss'
})
```

---

## HTTPインターセプターとは？（重要）

すべてのHTTPリクエストに自動でJWTトークンを付けてくれる仕組み。

```
APIリクエスト → インターセプター → Authorization: Bearer <token> を追加 → Rails
```

これがあるとサービスごとにトークンを書かなくていい。
設定方法は `07_routing_services.md` で説明する。

---

## 次のステップ

→ [07_routing_services.md](07_routing_services.md) でルーティングとサービスを設定する
