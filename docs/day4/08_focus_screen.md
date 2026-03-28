# Day 4-① フォーカス画面

## この画面の役割

- 今日まだ処理していない最優先タスクを1件表示する
- 「達成」「スキップ」「今日はここまで」の3択だけ
- 全タスク完了 or「今日はここまで」→ `/review` に自動遷移

---

## コンポーネント実装

```typescript
// app/components/focus/focus.ts
import { Component, signal, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FocusService } from '../../services/focus.service';
import { Task } from '../../services/task.service';

@Component({
  selector: 'app-focus',
  imports: [],
  templateUrl: './focus.html',
  styleUrl: './focus.scss'
})
export class FocusComponent implements OnInit {
  private focusService = inject(FocusService);
  private router = inject(Router);

  currentTask = signal<Task | null>(null);
  loading = signal(true);

  ngOnInit() {
    this.loadCurrent();
  }

  loadCurrent() {
    this.loading.set(true);
    this.focusService.getCurrent().subscribe(res => {
      // レスポンスが { current: null } の場合はタスクなし
      if ('current' in res && res.current === null) {
        this.currentTask.set(null);
      } else {
        this.currentTask.set(res as Task);
      }
      this.loading.set(false);
    });
  }

  done() {
    const task = this.currentTask();
    if (!task) return;
    this.focusService.log(task.id, 'done').subscribe(() => {
      this.loadCurrent();
    });
  }

  skip() {
    const task = this.currentTask();
    if (!task) return;
    this.focusService.log(task.id, 'skip').subscribe(() => {
      this.loadCurrent();
    });
  }

  finish() {
    this.router.navigate(['/review']);
  }
}
```

---

## HTML実装

```html
<!-- app/components/focus/focus.html -->
@if (loading()) {
  <p>読み込み中...</p>
} @else if (currentTask()) {
  <div class="focus-card">
    <p class="task-title">{{ currentTask()!.title }}</p>

    <div class="actions">
      <button (click)="done()">達成</button>
      <button (click)="skip()">スキップ</button>
      <button (click)="finish()">今日はここまで</button>
    </div>
  </div>
} @else {
  <!-- 全タスク完了 -->
  <div class="all-done">
    <p>今日のタスクは全部終わったよ！</p>
    <button (click)="finish()">振り返りへ</button>
  </div>
}
```

### ポイント解説

**`(click)="done()"`** — クリックイベントをメソッドにバインドする。

**`currentTask()!.title`** — `!` はTypeScriptの「nullではない」を明示するもの（Non-null assertion）。`@if` でnullチェック済みなので安全。

---

## CSS（最低限）

```scss
/* app/components/focus/focus.scss */
.focus-card {
  text-align: center;
  padding: 2rem;
}

.task-title {
  font-size: 2rem;
  font-weight: bold;
  margin-bottom: 2rem;
}

.actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

button {
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  cursor: pointer;
}
```

---

## 動作確認チェックリスト

- [ ] `/focus` を開くとタスクが表示される
- [ ] 「達成」を押すと次のタスクに変わる
- [ ] 「スキップ」を押すと次のタスクに変わる
- [ ] 全タスク消化 or「今日はここまで」で `/review` に遷移する

---

## 次のステップ

→ [09_review_tasks_screen.md](09_review_tasks_screen.md) で振り返り・タスク管理画面を作る
