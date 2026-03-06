import 'package:flutter/material.dart';

class HelpSection {
  final String title;
  final IconData icon;
  final List<HelpItem> items;

  HelpSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class HelpItem {
  final String title;
  final String content;
  final IconData? icon;

  HelpItem({
    required this.title,
    required this.content,
    this.icon,
  });
}

// Данные для руководства
class HelpData {
  static List<HelpSection> getSections() {
    return [
      HelpSection(
        title: 'Вход в приложение',
        icon: Icons.login,
        items: [
          HelpItem(
            title: 'Первый вход',
            content:
                'На главном экране введите ваш логин (обычно это email) и пароль, которые вы используете на сайте cabinet.adelipnz.ru\n\nПри желании отметьте галочку "Запомнить меня", чтобы не вводить логин при каждом входе.\n\nНажмите кнопку "Войти".',
            icon: Icons.key,
          ),
          HelpItem(
            title: 'Если забыли пароль',
            content:
                'Если вы не знаете или забыл пароль, то вы можете его восстановить по ссылке под формой ввода пароля. Введите адрес электронной почты и на вашу почту придет письмо с новым паролем. В случае неудачи обратитесь к администратору или используйте функцию восстановления пароля на сайте cabinet.adelipnz.ru',
            icon: Icons.lock_reset,
          ),
        ],
      ),
      HelpSection(
        title: 'Главное меню',
        icon: Icons.home,
        items: [
          HelpItem(
            title: 'Разделы приложения',
            content:
                'После входа вы попадаете на главный экран с разделами:\n\n📅 Расписание занятий - просмотр ежедневного расписания\n📚 Назначенные курсы - список ваших курсов\n📝 Заполнить анкету - анкета пациента\n👤 Профиль - ваши личные данные',
            icon: Icons.menu,
          ),
          HelpItem(
            title: 'Верхняя панель',
            content:
                '• 👤 Профиль - быстрый переход к вашим данным\n• ↪️ Выход - завершение сеанса работы',
            icon: Icons.info,
          ),
        ],
      ),
      HelpSection(
        title: 'Профиль и подопечные',
        icon: Icons.person,
        items: [
          HelpItem(
            title: 'Профиль пользователя',
            content:
                'В профиле доступны три вкладки:\n\n👤 Профиль - ваши данные (логин, имя, email)\n🔒 Безопасность - смена пароля\n👨‍👩‍👧 Подопечные - информация о ваших подопечных',
            icon: Icons.badge,
          ),
          HelpItem(
            title: 'Редактирование профиля',
            content:
                'Нажмите кнопку "Редактировать" в правом верхнем углу, внесите изменения и нажмите "Сохранить".',
            icon: Icons.edit,
          ),
          HelpItem(
            title: 'Смена пароля',
            content:
                '1. Введите текущий пароль\n2. Введите новый пароль (минимум 6 символов)\n3. Подтвердите новый пароль\n4. Нажмите "Изменить пароль"',
            icon: Icons.lock,
          ),
          HelpItem(
            title: 'Мои подопечные',
            content:
                'На вкладке "Подопечные" отображаются все ваши подопечные (дети, внуки и т.д.):\n• ФИО подопечного\n• Дата рождения\n• Возраст\n• Родственная связь',
            icon: Icons.family_restroom,
          ),
        ],
      ),
      HelpSection(
        title: 'Расписание занятий',
        icon: Icons.calendar_month,
        items: [
          HelpItem(
            title: 'Как это работает',
            content:
                'Расписание загружается автоматически при открытии раздела. Отображаются все занятия на сегодня.\n\nДля обновления потяните список вниз или нажмите кнопку "Обновить".',
            icon: Icons.update,
          ),
          HelpItem(
            title: 'Карточка занятия',
            content:
                'Каждое занятие содержит:\n• ⏰ Время начала и окончания\n• 🏥 Название процедуры\n• 🏢 Номер кабинета\n• 👨‍⚕️ Имя специалиста\n• ⏱️ Длительность',
            icon: Icons.info,
          ),
          HelpItem(
            title: 'Детальная информация',
            content:
                'Нажмите на любое занятие, чтобы увидеть полное описание процедуры и дополнительные заметки.',
            icon: Icons.info_outline,
          ),
          HelpItem(
            title: 'Если занятий нет',
            content:
                'При отсутствии занятий на сегодня вы увидите сообщение: "На сегодня занятий нет"',
            icon: Icons.event_busy,
          ),
        ],
      ),
      HelpSection(
        title: 'Назначенные курсы',
        icon: Icons.school,
        items: [
          HelpItem(
            title: 'Статистика курсов',
            content:
                'В верхней части экрана отображается статистика:\n• 📊 Всего заявок\n• ✅ Выполнено\n• ⏳ В обработке\n• ❌ Отменено',
            icon: Icons.analytics,
          ),
          HelpItem(
            title: 'Статусы курсов',
            content:
                'Цветовая индикация статусов:\n🟢 Зеленый - Выполнена\n🟠 Оранжевый - В обработке\n🔵 Синий - В плане заезда\n🔴 Красный - Отменена\n⚪ Серый - Неизвестно',
            icon: Icons.color_lens,
          ),
          HelpItem(
            title: 'Детальная информация',
            content:
                'Нажмите на карточку курса, чтобы увидеть:\n• Полное описание заявки\n• Номер записи на курс\n• Даты начала и окончания\n• Контакты для связи',
            icon: Icons.details,
          ),
          HelpItem(
            title: 'Контакты',
            content:
                'В детальной информации доступны интерактивные контакты:\n📞 Телефон - нажмите, чтобы позвонить\n✉️ Email - нажмите, чтобы отправить письмо',
            icon: Icons.contact_phone,
          ),
        ],
      ),
      HelpSection(
        title: 'Уведомления',
        icon: Icons.notifications,
        items: [
          HelpItem(
            title: 'Что вызывает уведомления',
            content:
                'Вы будете получать уведомления при:\n• 📅 Изменении в расписании\n• 📚 Изменении статуса курса',
            icon: Icons.notifications_active,
          ),
          HelpItem(
            title: 'Действия с уведомлениями',
            content:
                '• Нажмите на уведомление - откроется соответствующий раздел\n• Смахните - чтобы закрыть уведомление',
            icon: Icons.touch_app,
          ),
        ],
      ),
      HelpSection(
        title: 'Выход и поддержка',
        icon: Icons.support_agent,
        items: [
          HelpItem(
            title: 'Выход из приложения',
            content:
                '1. Нажмите на иконку ↪️ Выход в правом верхнем углу\n2. Подтвердите действие в диалоговом окне',
            icon: Icons.logout,
          ),
          HelpItem(
            title: 'Поддержка',
            content:
                'По всем вопросам обращайтесь:\n📞 Телефон: +7 (8412) 44-44-71\n✉️ Email: adeli-penza@mail.ru\n🌐 Сайт: https://cabinet.adelipnz.ru',
            icon: Icons.contact_support,
          ),
          HelpItem(
            title: 'Технические требования',
            content:
                '• Android: версия 6.0 и выше\n• Интернет: постоянно подключение\n• Память: около 50 МБ свободного места',
            icon: Icons.phone_android,
          ),
        ],
      ),
    ];
  }
}
