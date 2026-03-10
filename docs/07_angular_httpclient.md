# 07 - AngularのHttpClient

[← 目次に戻る](./00_index.md)

---

## HttpClientとは

AngularがHTTPリクエスト（APIの呼び出し）を行うための機能です。
これを使ってRails APIにデータを取りに行きます。

---

## providersへの登録

`frontend/src/app/app.config.ts`

```typescript
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';  // 追加

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient()   // 追加
  ]
};
```

### providersとは

Angularでは使いたい機能を `providers` に登録する必要があります。
登録することでアプリ全体のどこからでもその機能を使えるようになります。

```
providers に登録 → アプリ全体で使える
登録しない       → 使おうとするとエラー
```

---

[次へ → 08 - Angularのコンポーネント](./08_angular_component.md)
