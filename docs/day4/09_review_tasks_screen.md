# Day 4-② 振り返り画面・タスク管理画面

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
    this.reviewService.getToday().subscribe(data => {
      this.summary.set(data);
    });
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
- 並び替え（ドラッグ&ドロップは後回し、上下ボタンでOK）

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
    this.taskService.getTasks().subscribe(tasks => {
      this.tasks.set(tasks);
    });
  }

  addTask() {
    const title = this.newTitle().trim();
    if (!title) return;

    this.taskService.createTask(title).subscribe({
      next: () => {
        this.newTitle.set('');
        this.loadTasks();
      },
      error: (err) => {
        alert(err.error?.error ?? 'エラーが発生しました');
      }
    });
  }

  deleteTask(id: number) {
    this.taskService.deleteTask(id).subscribe(() => {
      this.loadTasks();
    });
  }

  moveUp(index: number) {
    if (index === 0) return;
    const tasks = [...this.tasks()];
    [tasks[index - 1], tasks[index]] = [tasks[index], tasks[index - 1]];
    const order = tasks.map(t => t.id);
    this.taskService.reorder(order).subscribe(() => {
      this.loadTasks();
    });
  }

  moveDown(index: number) {
    const tasks = this.tasks();
    if (index === tasks.length - 1) return;
    const arr = [...tasks];
    [arr[index], arr[index + 1]] = [arr[index + 1], arr[index]];
    const order = arr.map(t => t.id);
    this.taskService.reorder(order).subscribe(() => {
      this.loadTasks();
    });
  }
}
```

### HTML

```html
<!-- app/components/tasks/tasks.html -->
<div class="tasks">
  <h2>タスク管理</h2>

  <!-- 追加フォーム -->
  <form (ngSubmit)="addTask()">
    <input
      [(ngModel)]="newTitle"
      [ngModel]="newTitle()"
      (ngModelChange)="newTitle.set($event)"
      placeholder="タスク名を入力"
      name="title"
    />
    <button type="submit">追加</button>
  </form>

  <!-- タスク一覧 -->
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

### FormsModule と ngModel

**`[(ngModel)]`** = 双方向バインディング。入力値とTypeScriptの変数を同期する。
ただし Signals と組み合わせるときは少し書き方が変わる（上記参照）。

`FormsModule` を `imports` に追加しないと動かないので注意。

---

## 次のステップ

→ [10_debug.md](10_debug.md) で動作確認とよくあるエラーの対処
