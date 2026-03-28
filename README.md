# Zennly

> 大きな夢を、今日の一歩に。

長期目標を6階層（10年→5年→1年→今月→今週→今日）に逆算し、AIが次のステップを提案する目標管理アプリ。

---

## 技術スタック

| | 技術 |
|---|---|
| フロントエンド | Angular 19 |
| バックエンド | Rails 8 API |
| DB | PostgreSQL |
| AI | Anthropic API (Claude) |
| 起動 | Docker Compose |

## 開発環境のセットアップ

```bash
docker compose up
```

- フロントエンド: http://localhost:4200
- バックエンド: http://localhost:3000

## 主な機能

- 6階層の目標設定（10年後〜今日）
- AIによる下位目標の逆算提案
- 毎日の振り返り日記
- 気分・達成度の記録
