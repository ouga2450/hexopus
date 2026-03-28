# Hexopus 4日間学習ロードマップ

## アプリ概要
ADHDでも続けられる習慣アプリ。タスクを6つに絞り、1つずつ処理するだけ。

**スタック:** Rails 8 API + Angular 19 + PostgreSQL
**構成:**
```
RailsAPI_test/
├── backend/   # Rails API
└── frontend/  # Angular
```

---

## 4日間スケジュール

| 日 | テーマ | ファイル |
|---|---|---|
| Day 1 | Railsとは・モデル・DB設計 | [day1/01_rails_intro.md](day1/01_rails_intro.md) / [day1/02_models.md](day1/02_models.md) |
| Day 2 | ルーティング・コントローラー全部・CORS | [day2/03_routing.md](day2/03_routing.md) / [day2/04_controllers.md](day2/04_controllers.md) / [day2/05_cors.md](day2/05_cors.md) |
| Day 3 | Angular入門・ルーティング・サービス | [day3/06_angular_intro.md](day3/06_angular_intro.md) / [day3/07_routing_services.md](day3/07_routing_services.md) |
| Day 4 | 3画面実装・動作確認 | [day4/08_focus_screen.md](day4/08_focus_screen.md) / [day4/09_review_tasks_screen.md](day4/09_review_tasks_screen.md) / [day4/10_debug.md](day4/10_debug.md) |

---

## 完成イメージ

```
画面遷移:
/tasks  →（タスクを6つ登録）→  /focus  →（達成/スキップ繰り返し）→  /review
                                  ↑_____________「明日またがんばる」___________↑
```

## 動かし方
```bash
docker compose up        # バックエンド・DB起動
cd frontend && ng serve  # Angular起動（別ターミナル）
```
