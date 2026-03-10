# 08 - Angularのコンポーネント

[← 目次に戻る](./00_index.md)

---

## コンポーネントとは

Angularの画面は**コンポーネント**という単位で構成されます。
1つのコンポーネントは以下の3つのファイルで構成されます。

```
app.ts      ← ロジック（データの取得・処理）
app.html    ← テンプレート（画面の構造）
app.scss    ← スタイル（見た目）
```

---

## signalとは

画面と連動する変数です。値が変わると画面も自動的に更新されます。

```typescript
message = signal('読み込み中...');   // 初期値を設定

// 値を更新すると画面も変わる
this.message.set('新しいメッセージ');

// 値を読む
this.message()   // () を付けて読む
```

普通の変数との違い：

```typescript
// 普通の変数 → 値を変えても画面は更新されない
name = '田中';
name = '鈴木';   // 画面はそのまま

// signal → 値を変えると画面も更新される
name = signal('田中');
name.set('鈴木');   // 画面も「鈴木」に変わる
```

---

## ngOnInitとは

コンポーネントが画面に表示されたときに自動で実行されるメソッドです。
APIの呼び出しはここで行います。

```typescript
ngOnInit() {
  // ページが表示されたら自動でここが実行される
  // → APIを呼び出してデータを取得する
}
```

---

## 非同期処理とsubscribe

APIへのリクエストは「時間がかかる処理」です。
レスポンスが返ってくるまで待っている間も、ブラウザは動き続けます。

```
APIを呼び出す
    ↓
待機中（画面は操作できる）
    ↓
レスポンスが来たら値を更新 → 画面が変わる
```

`subscribe()` はレスポンスが来たときに実行する処理を登録するものです。

```typescript
this.http.get<{ message: string }>('http://localhost:3000/api/hello')
  .subscribe({
    next: (data) => this.message.set(data.message),    // 成功したとき
    error: () => this.message.set('接続に失敗しました') // 失敗したとき
  });
```

---

## コンポーネント全体のコード

`frontend/src/app/app.ts`

```typescript
import { Component, signal, inject, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  private http = inject(HttpClient);       // HttpClientを使えるようにする
  message = signal('読み込み中...');       // 画面に表示する値（初期値）

  ngOnInit() {                             // 画面表示時に自動実行
    this.http.get<{ message: string }>('http://localhost:3000/api/hello')
      .subscribe({
        next: (data) => this.message.set(data.message),
        error: () => this.message.set('接続に失敗しました')
      });
  }
}
```

**キーワードまとめ：**

| キーワード | 意味 |
|-----------|------|
| `@Component` | このクラスがコンポーネントであることを宣言する |
| `signal` | 画面と連動する変数 |
| `inject(HttpClient)` | HttpClientを使えるようにする |
| `ngOnInit()` | 画面表示時に自動実行されるメソッド |
| `http.get<T>(url)` | GETリクエストを送る |
| `subscribe()` | レスポンスが来たときの処理を登録する |

---

[次へ → 09 - Angularのテンプレート](./09_angular_template.md)
