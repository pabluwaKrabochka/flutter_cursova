lib/
├── app/
│   ├── config/         # Константи, оточення (env)
│   ├── di/             # Service Locator (get_it)
│   ├── router/         # Навігація (якщо будеш додавати)
│   ├── theme/          # Кольори, шрифти, теми
│   └── utils/          # Хелпери, логер, валідатори
├── data/
│   ├── models/         # Глобальні моделі даних
│   ├── services/       # SQLite, Shared Preferences
│   └── repositories/   # Глобальні репозиторії (напр. налаштування теми)
├── domain/             # Глобальні сутності та Use Cases
├── features/           # Кожна фіча — це окремий світ
│   ├── transactions/   # Фіча транзакцій
│   │   ├── data/       # Репозиторії фічі
│   │   ├── state/      # BLoC / Cubit
│   │   └── ui/         # Сторінки та специфічні віджети
│   └── analytics/      # Фіча графіків (fl_chart)
└── shared/             # Спільні віджети (кнопки, текст-філди)