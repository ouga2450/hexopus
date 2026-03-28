# Day 1-① Railsとは・プロジェクト構成

## Railsとは？

**Ruby on Rails** はWebアプリを素早く作るためのフレームワーク（型）。
今回は **APIモード** で使う。APIモードとはHTMLを返さず、JSONだけを返すサーバーのこと。

```
ブラウザ（Angular）  ←→  Rails API  ←→  PostgreSQL（DB）
     画面を作る          データを返す       データを保存する
```

---

## プロジェクト確認

```bash
cd backend
cat config/application.rb  # config.api_only = true があればAPIモード
```

---

## Railsのディレクトリ構成（重要なところだけ）

```
backend/
├── app/
│   ├── controllers/   # リクエストを受けて処理する（← 今回よく触る）
│   ├── models/        # DBとやりとりする（← 今回よく触る）
│   └── views/         # HTMLテンプレート（APIモードでは使わない）
├── config/
│   └── routes.rb      # URLとコントローラーの対応表（← 今回よく触る）
└── db/
    ├── migrate/        # テーブル定義の履歴
    └── schema.rb       # 現在のDB構造（自動生成）
```

---

## MVCとは

Railsは **MVC（Model-View-Controller）** という設計パターンを使う。

| 役割 | 担当 | 例 |
|---|---|---|
| **M**odel | DBとのやりとり | `Task.where(...)` |
| **V**iew | 画面（APIでは使わない） | - |
| **C**ontroller | リクエストを受けてModelを呼ぶ | `def index; render json: ... end` |

---

## 次のステップ

→ [02_models.md](02_models.md) でモデルとマイグレーションを作る
