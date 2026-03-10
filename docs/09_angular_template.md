# 09 - Angularのテンプレート

[← 目次に戻る](./00_index.md)

---

## テンプレートとは

コンポーネントの画面構造を定義するHTMLファイルです。
通常のHTMLに加えて、Angular独自の構文が使えます。

---

## データバインディング

`{{ }}` を使うと、コンポーネントの値を画面に表示できます。

```html
<h1>{{ message() }}</h1>
```

`signal` の値は `()` を付けて読みます。
値が変わると画面も自動的に更新されます。

```
message の値が「読み込み中...」 → 画面に「読み込み中...」と表示
          ↓ APIからデータが返る
message の値が「こんにちは！」  → 画面が「こんにちは！」に変わる
```

---

## テンプレート構文

### 条件分岐

```html
@if (isLoggedIn) {
  <p>ログイン中です</p>
} @else {
  <p>ログインしてください</p>
}
```

### 繰り返し

```html
@for (task of tasks(); track task.id) {
  <li>{{ task.title }}</li>
}
```

---

## このプロジェクトのテンプレート

`frontend/src/app/app.html`

```html
<main>
  <h1>{{ message() }}</h1>
</main>

<router-outlet />
```

- `{{ message() }}` → signalの値を表示
- `<router-outlet />` → ルーティングに応じたページをここに表示する

---

[次へ → 10 - データの流れ全体像](./10_data_flow.md)
