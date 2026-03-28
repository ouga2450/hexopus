# Day 3-② Angularルーティング・サービス

## Angularのルーティングとは？

URLと表示するコンポーネントを対応させる設定。

```
/focus   → FocusComponent を表示
/review  → ReviewComponent を表示
/tasks   → TasksComponent を表示
```

---

## ルート設定

```typescript
// app/app.routes.ts
import { Routes } from '@angular/router';
import { FocusComponent } from './components/focus/focus';
import { ReviewComponent } from './components/review/review';
import { TasksComponent } from './components/tasks/tasks';

export const routes: Routes = [
  { path: '',       redirectTo: '/focus', pathMatch: 'full' },  // トップは/focusへ
  { path: 'focus',  component: FocusComponent },
  { path: 'review', component: ReviewComponent },
  { path: 'tasks',  component: TasksComponent },
];
```

---

## ルーターアウトレット

URLに対応したコンポーネントを表示する場所を `<router-outlet>` で指定する。

```html
<!-- app/app.html -->
<app-header />
<main class="app-main">
  <router-outlet />   ← ここにページが表示される
</main>
<app-footer />
```

```typescript
// app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { HeaderComponent } from './components/header/header';
import { FooterComponent } from './components/footer/footer';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, HeaderComponent, FooterComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {}
```

---

## サービスとは？

コンポーネント間で共有するロジック（主にAPI通信）をまとめる場所。

```
FocusComponent ─┐
                ├─→ FocusService → Rails API
ReviewComponent─┘
```

同じAPIロジックを複数コンポーネントに書かずに済む。

---

## サービスの生成

```bash
ng g service services/task
ng g service services/focus
ng g service services/review
```

---

## TaskService の実装

```typescript
// app/services/task.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';

const API = 'http://localhost:3000/api';

export interface Task {
  id: number;
  title: string;
  priority: number;
}

@Injectable({ providedIn: 'root' })
export class TaskService {
  private http = inject(HttpClient);

  // タスク一覧取得
  getTasks() {
    return this.http.get<Task[]>(`${API}/tasks`);
  }

  // タスク追加
  createTask(title: string) {
    return this.http.post<Task>(`${API}/tasks`, { task: { title } });
  }

  // タスク削除
  deleteTask(id: number) {
    return this.http.delete(`${API}/tasks/${id}`);
  }

  // 並び替え
  reorder(order: number[]) {
    return this.http.patch(`${API}/tasks/reorder`, { order });
  }
}
```

---

## FocusService の実装

```typescript
// app/services/focus.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Task } from './task.service';

const API = 'http://localhost:3000/api';

@Injectable({ providedIn: 'root' })
export class FocusService {
  private http = inject(HttpClient);

  // 今日の未処理タスクを1件取得
  getCurrent() {
    return this.http.get<Task | { current: null }>(`${API}/focus/current`);
  }

  // done / skip を記録
  log(taskId: number, status: 'done' | 'skip') {
    return this.http.post(`${API}/focus/log`, { task_id: taskId, status });
  }
}
```

---

## ReviewService の実装

```typescript
// app/services/review.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';

const API = 'http://localhost:3000/api';

export interface ReviewSummary {
  done: number;
  skip: number;
  remaining: number;
  total: number;
}

@Injectable({ providedIn: 'root' })
export class ReviewService {
  private http = inject(HttpClient);

  getToday() {
    return this.http.get<ReviewSummary>(`${API}/review/today`);
  }
}
```

---

## サービスをコンポーネントで使う方法

```typescript
import { inject } from '@angular/core';
import { FocusService } from '../../services/focus.service';

export class FocusComponent {
  private focusService = inject(FocusService);  // ← inject() で取得

  ngOnInit() {
    this.focusService.getCurrent().subscribe(task => {
      console.log(task);  // APIのレスポンスが入ってくる
    });
  }
}
```

**`.subscribe()`** — Observableの値を受け取る。HTTPリクエストはObservableで返ってくる。

---

## 次のステップ

→ [Day 4: 08_focus_screen.md](../day4/08_focus_screen.md) で画面を実装する
