# Rails × Angular 学習教材

## 学習の流れ

```
全体像を掴む → 通信の仕組みを知る → バックを作る → フロントを作る → つながりを確認する
```

---

## 1. 全体像

- [01 - Webアプリの基本構造](./01_web_basics.md)
  - クライアントとサーバー、HTTPとは
- [03 - Rails API + Angularの構成](./03_rails_api_angular.md)
  - なぜ分離するのか、SPAとは、JSONとは
- [02 - 普通のRailsアプリ（MVC）](./02_rails_mvc.md)
  - MVCとは、サーバーサイドレンダリングとの違い

## 2. 通信の仕組み

- [04 - CORSとは](./04_cors.md)
  - 同一オリジンポリシー、rack-corsの設定

## 3. バックエンド（Rails）

- [05 - Railsのルーティング](./05_rails_routing.md)
  - URLとコントローラーの対応、namespace
- [06 - Railsのコントローラー](./06_rails_controller.md)
  - JSONを返す、module とは
- [11 - このプロジェクトのRails実装](./11_rails_api_this_project.md)
  - Genre・Item の CRUD

## 4. フロントエンド（Angular）

- [13 - Angularのアーキテクチャ](./13_angular_architecture.md)
  - SPAの仕組み、コンポーネントの基本構造、3層アーキテクチャ
- [08 - Angularのコンポーネント](./08_angular_component.md)
  - signal、ngOnInit、非同期処理とsubscribe
- [09 - Angularのテンプレート](./09_angular_template.md)
  - データバインディング、テンプレート構文（@for/@if）
- [07 - AngularのHttpClient](./07_angular_httpclient.md)
  - HTTPリクエストの書き方、Serviceとは

## 5. まとめ

- [10 - データの流れ全体像](./10_data_flow.md)
  - リクエストからレスポンスまでの流れ、ファイル構成
- [12 - フルスタック通信まとめ](./12_fullstack_summary.md)
  - 全体フロー、HTTPメソッドとCRUDの対応、キーワード一覧
