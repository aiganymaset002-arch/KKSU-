# KKSU Online — App Review information

Reply to App Review in App Store Connect and paste the same text into
**App Review Information → Notes**. Replace the `<…>` placeholders first.

---

Hello App Review team,

Thank you for your message. Below is the information you requested. A screen recording captured on a physical iPhone running the latest iOS is attached.

**1. Screen recording**

The recording starts with launching the app and shows:
- registration of a new account, login, logout and **account deletion** ("Профиль" → "Удалить аккаунт");
- the student flow: courses and lessons (live-lesson link, lesson video, notes, files), homework, tests, schedule and chat with a teacher;
- the teacher flow: the course builder (creating a course and a lesson);
- user-generated content safety:
  - **reporting** a chat message (long press → Report);
  - **reporting and blocking** a user (chat → "…" menu → Report user / Block);
  - **reporting** a project in the Virtual Exhibition ("…" → Report);
  - the list of blocked users (Profile → Blocked users);
  - the administrator's moderation screen (Profile → Moderation and reports);
- accessing paid content: a paid course is locked and unlocked with an In-App Purchase (sandbox).

**2. Purpose and target audience**

KKSU Online is the learning platform of Comfort School (Kazakhstan). It serves children and teenagers aged 7–18, including students with special educational needs (SEN), together with their parents and teachers.

It solves a real problem: learning materials, homework, schedules, progress and communication are usually scattered across messengers and paper. KKSU Online keeps them in one accessible app. It includes:
- courses and lessons built by teachers: live online lessons, recorded video, notes, files, tests and homework;
- an individual learning plan and progress tracking for each student;
- a parent cabinet;
- accessibility settings: larger text, high contrast, simplified interface and text alternatives for media.

**3. How to access the app**

Registration is open to everyone. Students and parents get access immediately. Teacher and staff accounts are activated by the school administrator.

Demo accounts:
- Student: `<student email>` / `<password>`
- Parent: `<parent email>` / `<password>`
- Teacher: `<teacher email>` / `<password>` (already approved; can open the course builder)
- Administrator: `<admin email>` / `<password>` (can open the moderation screen)

Main features (the interface is in Russian; Russian names are in quotes):
- "Кабинет" tab — the user's home cabinet.
- "Модули" tab → "Курсы и уроки" — courses and lessons.
- "Чат" tab — messages. Long-press a message → "Пожаловаться" (Report); the "…" menu → "Заблокировать" (Block).
- "Профиль" tab:
  - "Удалить аккаунт" — Delete account;
  - "Заблокированные пользователи" — Blocked users;
  - "Модерация и жалобы" — Moderation, for the administrator.

No sample files are needed.

**4. External services**

- **Supabase** (supabase.com): user authentication (email and password, password reset by one-time code) and the database. Row-level security restricts every record to the people allowed to see it.
- **Apple In-App Purchase (StoreKit 2)**: all digital content — courses, programs, student status and subscriptions.
- **YouTube** (youtube-nocookie.com embed): teachers can attach a recorded lesson hosted on YouTube.
- **Jitsi Meet, Zoom, Google Meet, Microsoft Teams**: live lessons open through a link in the user's browser or app.
- **Bank transfer (Kaspi and other Kazakhstan banks)**: used only for in-person services that are consumed outside the app, such as conferences and events (Guideline 3.1.3(e)). Digital content is sold only through In-App Purchase.
- **AI assistant**: works locally on the device by default. If the school connects its own AI server, a student's questions are sent to it only with parental consent.

**5. Regional differences**

The app works the same in all regions. The interface is in Russian. In-App Purchase prices follow App Store pricing in each storefront.

**6. Regulated industry and third-party material**

The app is not in a regulated industry and does not distribute protected third-party material. Teachers confirm that they own or have the rights to the materials they publish, as required by the Terms of Use. Students keep ownership of their own projects.

**User-generated content safeguards (Guideline 1.2)**

- The Terms of Use are accepted at registration. They state zero tolerance for objectionable content and abusive users.
- Chat messages are checked by a filter of objectionable words before sending.
- Users can report any message, project or user, and can block abusive users. Reported content is hidden from the reporter immediately.
- The administrator is notified of every report. Reports are reviewed within 24 hours: the content is removed and, when needed, the offending account is blocked.
- Contact: `<support email>`.

Thank you!

---

## Как записать видео (на iPhone)

1. **Настройки → Пункт управления** → добавь **Запись экрана**.
2. Открой Пункт управления, нажми кнопку записи и подожди 3 секунды.
3. Пройди по сценарию из раздела 1: запуск → регистрация → вход → курсы → чат → жалоба на сообщение → блокировка → выставка → жалоба на проект → покупка курса (Sandbox) → модерация (под администратором) → удаление аккаунта.
4. Останови запись — видео сохранится в «Фото». Длина 3–5 минут — нормально.

Для тестовой покупки на iPhone: **Настройки → App Store → Sandbox Account**, войди тестовым аккаунтом из App Store Connect (**Users and Access → Sandbox**).
