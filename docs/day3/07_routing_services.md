# Day 3-② Angularルーティング・認証・サービス

## Angularのルーティングとは？

URLと表示するコンポーネントを対応させる設定。

```
/login  → LoginComponent を表示
/focus  → FocusComponent を表示（要認証）
/review → ReviewComponent を表示（要認証）
/tasks  → TasksComponent を表示（要認証）
```

---

## ルート設定

```typescript
// app/app.routes.ts
import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login';
import { FocusComponent } from './components/focus/focus';
import { ReviewComponent } from './components/review/review';
import { TasksComponent } from './components/tasks/tasks';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '',       redirectTo: '/focus', pathMatch: 'full' },
  { path: 'login',  component: LoginComponent },
  { path: 'focus',  component: FocusComponent,  canActivate: [authGuard] },
  { path: 'review', component: ReviewComponent, canActivate: [authGuard] },
  { path: 'tasks',  component: TasksComponent,  canActivate: [authGuard] },
];
```

**`canActivate: [authGuard]`** — ログインしていないとそのページにアクセスできないようにする。

---

## 認証ガード（authGuard）

ログインしていない場合に `/login` に飛ばす。

```typescript
// app/guards/auth.guard.ts
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isLoggedIn()) {
    return true;
  }
  return router.createUrlTree(['/login']);
};
```

---

## HTTPインターセプター（トークン自動付与）

すべてのHTTPリクエストに `Authorization: Bearer <token>` を自動で付ける。

```typescript
// app/interceptors/auth.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = localStorage.getItem('token');
  if (token) {
    req = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`)
    });
  }
  return next(req);
};
```

`app.config.ts` に登録する：

```typescript
// app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { authInterceptor } from './interceptors/auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor])),  // ← インターセプターを登録
  ]
};
```

---

## AuthService

```typescript
// app/services/auth.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { tap } from 'rxjs/operators';

const API = 'http://localhost:3000/api';

export interface AuthUser {
  id: number;
  name: string;
  email: string;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  signup(name: string, email: string, password: string) {
    return this.http.post<{ token: string; user: AuthUser }>(`${API}/auth/signup`, { name, email, password }).pipe(
      tap(res => localStorage.setItem('token', res.token))
    );
  }

  login(email: string, password: string) {
    return this.http.post<{ token: string; user: AuthUser }>(`${API}/auth/login`, { email, password }).pipe(
      tap(res => localStorage.setItem('token', res.token))
    );
  }

  logout() {
    localStorage.removeItem('token');
    this.router.navigate(['/login']);
  }

  isLoggedIn(): boolean {
    return !!localStorage.getItem('token');
  }
}
```

**`tap`** — Observableの値を「覗き見」して副作用を実行する。値自体は変えない。ここではトークンの保存に使っている。

---

## TaskService

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

  getTasks() {
    return this.http.get<Task[]>(`${API}/tasks`);
  }

  createTask(title: string) {
    return this.http.post<Task>(`${API}/tasks`, { task: { title } });
  }

  deleteTask(id: number) {
    return this.http.delete(`${API}/tasks/${id}`);
  }

  reorder(order: number[]) {
    return this.http.patch(`${API}/tasks/reorder`, { order });
  }
}
```

トークンはインターセプターが自動で付けるので、サービス側には書かなくていい。

---

## FocusService / ReviewService

```typescript
// app/services/focus.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Task } from './task.service';

const API = 'http://localhost:3000/api';

@Injectable({ providedIn: 'root' })
export class FocusService {
  private http = inject(HttpClient);

  getCurrent() {
    return this.http.get<Task | { current: null }>(`${API}/focus/current`);
  }

  log(taskId: number, status: 'done' | 'skip') {
    return this.http.post(`${API}/focus/log`, { task_id: taskId, status });
  }
}
```

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

## サービスをコンポーネントで使う

```typescript
import { inject } from '@angular/core';
import { FocusService } from '../../services/focus.service';

export class FocusComponent {
  private focusService = inject(FocusService);

  ngOnInit() {
    this.focusService.getCurrent().subscribe(task => {
      console.log(task);
    });
  }
}
```

**`.subscribe()`** — Observableの値を受け取る。HTTPリクエストはObservableで返ってくる。

---

## 次のステップ

→ [Day 4: 08_focus_screen.md](../day4/08_focus_screen.md) で画面を実装する
