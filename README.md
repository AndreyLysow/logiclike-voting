# LogicLike Voting Platform

Публичная страница для голосования за идеи по развитию продукта **LogicLike**.  
Система ограничивает количество голосов с одного IP-адреса (не более **10 разных идей**).

---

## 🌐 Деплой

**Домен:** [https://fwwland.ru](https://fwwland.ru)  
**SSL:** установлен через Let’s Encrypt (Certbot)  
**Reverse-proxy:** Nginx (проксирует запросы на backend порт `4000`)

---

## ⚙️ Технологический стек

| Компонент | Технология |
|------------|-------------|
| Backend | Node.js (Fastify + TypeScript) |
| ORM | Prisma + PostgreSQL |
| Frontend | React (Vite) |
| DevOps | Docker, PM2, Nginx, Let’s Encrypt |

---

## 🧩 Основные возможности

- Просмотр списка идей (отсортированы по количеству голосов)
- Голосование за идею (по IP не более 10 голосов)
- Проверка повторного голосования
- Отображение оставшегося лимита голосов
- Подсчёт голосов в реальном времени

---

## 🧱 Архитектура проекта

```
logiclike-voting/
├── backend/
│   ├── src/
│   │   ├── db.ts
│   │   ├── env.ts
│   │   ├── server.ts
│   │   ├── utils/ip.ts
│   │   └── routes/
│   │       ├── ideas.ts
│   │       └── votes.ts
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── seed.ts
│   └── package.json
└── frontend/
    ├── src/
    │   ├── App.tsx
    │   ├── api.ts
    │   ├── components/IdeaCard.tsx
    │   └── styles/
    ├── vite.config.ts
    └── package.json
```

---

## 🗄️ Модель БД (Prisma)

```prisma
model Idea {
  id          Int      @id @default(autoincrement())
  title       String
  description String
  votesCount  Int      @default(0)
  votes       Vote[]
  @@index([votesCount, id])
}

model Vote {
  id         Int      @id @default(autoincrement())
  ideaId     Int
  ipAddress  String
  createdAt  DateTime @default(now())
  idea       Idea     @relation(fields: [ideaId], references: [id])
  @@unique([ideaId, ipAddress])
}
```

---

## 🚀 API

### `GET /ideas`
Возвращает список идей и статистику по текущему IP.

```json
{
  "ideas": [
    { "id": 1, "title": "Быстрые мини-игры", "votesCount": 4, "hasVoted": true },
    { "id": 2, "title": "Офлайн-режим", "votesCount": 6, "hasVoted": false }
  ],
  "ip": "127.0.0.1",
  "ipVotesUsed": 3,
  "ipVotesLeft": 7,
  "maxVotesPerIp": 10
}
```

### `POST /ideas/:id/vote`
Увеличивает количество голосов, если:
- этот IP ещё не голосовал за идею;
- общее количество голосов с IP меньше 10.

Ошибки:
- `409 Conflict` — уже голосовал;
- `409 Conflict` — превышен лимит голосов.

---

## 🧠 Особенности реализации

- Голосование и обновление счётчика выполняются в одной транзакции.
- Лимиты по IP проверяются перед записью и на уровне БД.
- Клиентская блокировка при превышении лимита (сообщение «Можно выбрать только 10 идей»).

---

## 🔒 Безопасность и инфраструктура

- SSL — Let’s Encrypt  
- CORS — ограничен доменом `https://fwwland.ru`  
- Nginx — проксирует `/api` → `localhost:4000`  
- PM2 — управление сервисом `logiclike-backend`

---

## 🧰 Быстрый запуск локально

```bash
# Backend
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name init
npx ts-node prisma/seed.ts
npm run dev

# Frontend
cd ../frontend
npm install
npm run dev
```

---





## 🪶 Автор

**Лысов Андрей** — fullstack-разработчик (Next.js, Node.js, DevOps)  
Платформа создана в рамках тестового задания для LogicLike.  
📧 [lysow@yandex.ru](mailto:lysow@yandex.ru)
