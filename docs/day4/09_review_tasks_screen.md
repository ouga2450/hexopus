# Day 4-② ログイン画面・振り返り画面・タスク管理画面

---

## ログイン画面（LoginComponent）

### 役割
- メールアドレスとパスワードでログイン
- 初回ユーザーはここからサインアップもできる
- ログイン成功 → `/focus` に遷移

### コンポーネント

```typescript
// app/components/login/login.ts
import { Component, signal, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.scss'
})
export class LoginComponent {
  private authService = inject(AuthService);
  private router = inject(Router);

  email = signal('');
  password = signal('');
  name = signal('');
  isSignup = signal(false);
  errorMessage = signal('');

  submit() {
    this.errorMessage.set('');
    const action = this.isSignup()
      ? this.authService.signup(this.name(), this.email(), this.password())
      : this.authService.login(this.email(), this.password());

    action.subscribe({
      next: () => this.router.navigate(['/focus']),
      error: (err) => this.errorMessage.set(err.error?.error ?? 'エラーが発生しました')
    });
  }

  toggleMode() {
    this.isSignup.update(v => !v);
    this.errorMessage.set('');
  }
}
```

### HTML

```html
<!-- app/components/login/login.html -->
<div class="login">
  <h1>Hexopus</h1>
  <h2>{{ isSignup() ? 'アカウント登録' : 'ログイン' }}</h2>

  <form (ngSubmit)="submit()">
    @if (isSignup()) {
      <input
        [ngModel]="name()"
        (ngModelChange)="name.set($event)"
        name="name"
        placeholder="名前"
        required
      />
    }
    <input
      [ngModel]="email()"
      (ngModelChange)="email.set($event)"
      name="email"
      type="email"
      placeholder="メールアドレス"
      required
    />
    <input
      [ngModel]="password()"
      (ngModelChange)="password.set($event)"
      name="password"
      type="password"
      placeholder="パスワード（8文字以上）"
      required
    />

    @if (errorMessage()) {
      <p class="error">{{ errorMessage() }}</p>
    }

    <button type="submit">{{ isSignup() ? '登録' : 'ログイン' }}</button>
  </form>

  <button (click)="toggleMode()">
    {{ isSignup() ? 'ログインはこちら' : 'アカウント登録はこちら' }}
  </button>
</div>
```

---

## 振り返り画面（ReviewComponent）

### 役割
- 今日の達成数・スキップ数を表示するだけ
- 「明日またがんばる」ボタン → `/focus` に戻る

### コンポーネント

```typescript
// app/components/review/review.ts
import { Component, signal, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ReviewService, ReviewSummary } from '../../services/review.service';

@Component({
  selector: 'app-review',
  imports: [],
  templateUrl: './review.html',
  styleUrl: './review.scss'
})
export class ReviewComponent implements OnInit {
  private reviewService = inject(ReviewService);
  private router = inject(Router);

  summary = signal<ReviewSummary | null>(null);

  ngOnInit() {
    this.reviewService.getToday().subscribe(data => this.summary.set(data));
  }

  backToFocus() {
    this.router.navigate(['/focus']);
  }
}
```

### HTML

```html
<!-- app/components/review/review.html -->
@if (summary()) {
  <div class="review">
    <h2>今日の結果</h2>
    <p>達成：{{ summary()!.done }} 個</p>
    <p>スキップ：{{ summary()!.skip }} 個</p>
    <button (click)="backToFocus()">明日またがんばる</button>
  </div>
} @else {
  <p>読み込み中...</p>
}
```

---

## タスク管理画面（TasksComponent）

### 役割
- タスクの一覧表示・追加・削除
- 上下ボタンで優先順位の並び替え

### コンポーネント

```typescript
// app/components/tasks/tasks.ts
import { Component, signal, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TaskService, Task } from '../../services/task.service';

@Component({
  selector: 'app-tasks',
  imports: [FormsModule],
  templateUrl: './tasks.html',
  styleUrl: './tasks.scss'
})
export class TasksComponent implements OnInit {
  private taskService = inject(TaskService);

  tasks = signal<Task[]>([]);
  newTitle = signal('');

  ngOnInit() {
    this.loadTasks();
  }

  loadTasks() {
    this.taskService.getTasks().subscribe(tasks => this.tasks.set(tasks));
  }

  addTask() {
    const title = this.newTitle().trim();
    if (!title) return;

    this.taskService.createTask(title).subscribe({
      next: () => { this.newTitle.set(''); this.loadTasks(); },
      error: (err) => alert(err.error?.error ?? 'エラーが発生しました')
    });
  }

  deleteTask(id: number) {
    this.taskService.deleteTask(id).subscribe(() => this.loadTasks());
  }

  moveUp(index: number) {
    if (index === 0) return;
    const arr = [...this.tasks()];
    [arr[index - 1], arr[index]] = [arr[index], arr[index - 1]];
    this.taskService.reorder(arr.map(t => t.id)).subscribe(() => this.loadTasks());
  }

  moveDown(index: number) {
    const arr = [...this.tasks()];
    if (index === arr.length - 1) return;
    [arr[index], arr[index + 1]] = [arr[index + 1], arr[index]];
    this.taskService.reorder(arr.map(t => t.id)).subscribe(() => this.loadTasks());
  }
}
```

### HTML

```html
<!-- app/components/tasks/tasks.html -->
<div class="tasks">
  <h2>タスク管理</h2>

  <form (ngSubmit)="addTask()">
    <input
      [ngModel]="newTitle()"
      (ngModelChange)="newTitle.set($event)"
      placeholder="タスク名を入力"
      name="title"
    />
    <button type="submit">追加</button>
  </form>

  <ul>
    @for (task of tasks(); track task.id; let i = $index) {
      <li>
        <span>{{ task.priority }}. {{ task.title }}</span>
        <button (click)="moveUp(i)">↑</button>
        <button (click)="moveDown(i)">↓</button>
        <button (click)="deleteTask(task.id)">削除</button>
      </li>
    }
  </ul>
</div>
```

**`[(ngModel)]` vs `[ngModel] + (ngModelChange)`**

Signalsと組み合わせるときは双方向バインディング `[(ngModel)]` が使えないため、読み取りと書き込みを分けて書く。

---

## 次のステップ

→ [10_debug.md](10_debug.md) で動作確認とよくあるエラーの対処
