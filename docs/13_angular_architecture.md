# Angularのアーキテクチャ

[← 目次に戻る](./00_index.md)

---

## SPAとは

**SPA（Single Page Application）** とは、1枚のHTMLだけをサーバーから受け取り、
その後はJavaScriptがブラウザ上で画面を書き換え続けるアプリの仕組みです。

```
従来のWebアプリ：
  ページ遷移のたびにサーバーからHTMLを受け取る → 毎回画面が白くなる

SPA（Angular）：
  最初の1回だけHTMLを受け取る → その後はJSで書き換え → ページ遷移なし
```

### 起動の流れ

```
① ブラウザが localhost:4200 にアクセス
② index.html（1枚だけ）が返ってくる
③ index.html の <app-root> にAngularが全コンポーネントを流し込む
④ 以降はサーバーと通信せず、JSが画面を書き換え続ける
   （データが必要なときだけ Rails API に JSON を取りに行く）
```

### 重要なポイント

コンポーネント（`.ts` ファイル）は**アプリ起動時に全部まとめてメモリに展開**されます。
アクションのたびに読み込むのではなく、最初から全部ブラウザにある状態です。

---

## コンポーネントの基本構造

1つのコンポーネントは **3つのファイルセット** で構成されます。

```
header.ts    ← 「このコンポーネントの定義・設定」
header.html  ← 「画面に表示するHTML」
header.scss  ← 「見た目のスタイル」
```

### `.ts` ファイルの構造

```typescript
import { Component } from '@angular/core';  // ① 使う機能を取り込む

@Component({                    // ② 設定表（デコレータ）
  selector: 'app-header',       //   HTMLで使うタグ名
  imports: [],                  //   このコンポーネントが使う子コンポーネント
  templateUrl: './header.html', //   表示するHTMLファイル
  styleUrl: './header.scss'     //   スタイルファイル
})
export class Header {}          // ③ コンポーネント本体（静的表示なら空でいい）
```

| 部分 | 意味 |
|------|------|
| `import` | 使う機能だけを取り込む。不要なものは書かない |
| `@Component` | コンポーネントの設定表。`selector` でタグ名を定義する |
| `export class` | 他のファイルから `import` できるようにする |

---

## コンポーネントの親子関係

コンポーネントには階層があります。

```
main.ts          ← アプリの電源スイッチ。App を起動するだけ
  └── app.ts     ← 親コンポーネント（司令塔）。子を imports に登録して管理
        ├── header.ts
        ├── footer.ts
        ├── genre-sidebar.ts
        └── item-grid.ts
```

子コンポーネントを `app.html` で使うには、必ず `app.ts` の `imports` に追加が必要です。

```typescript
// app.ts
imports: [GenreSidebar, ItemGrid, Header, Footer]
//         ↑ここに書いた子だけ app.html で <app-xxx /> として使える
```

---

## 3層アーキテクチャ

Angularのデータ取得には3つの層があります。

```
genre.service.ts  ← JSON受取係（Railsと話す）
app.ts            ← 仕分け係（データを管理・各コンポーネントに配送）
genre-sidebar.ts  ← 画面表示係（受け取ったデータを見せる）
```

### データの流れ（ジャンル取得の例）

```
① ユーザーがページを開く
② app.ts の ngOnInit() が自動実行
③ genre.service.ts に「ジャンル一覧ちょうだい」と頼む
④ genre.service.ts が Rails に GET リクエスト
⑤ Rails が JSON で返す → [{ id: 1, name: "本" }, ...]
⑥ genre.service.ts が JSON を受け取って app.ts に渡す
⑦ app.ts が signal に保存 → genre-sidebar.ts に渡す
⑧ genre-sidebar.ts が画面に表示
```

### 各層の責務

| 層 | ファイル | やること |
|----|---------|---------|
| Service | `genre.service.ts` | RailsへのHTTPリクエスト。JSONの受け取り |
| Component（親） | `app.ts` | データの保持・管理。子への配送 |
| Component（子） | `genre-sidebar.ts` | 受け取ったデータを画面に表示 |

---

[← 目次に戻る](./00_index.md)
