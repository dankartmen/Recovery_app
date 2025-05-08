class RecoveryData {
  final int? id;
  final String name;
  final String gender;
  final double weight;
  final double height;
  final String mainInjuryType;
  final String specificInjury;
  final int painLevel;
  final String trainingTime;

  RecoveryData({
    this.id,
    required this.name,
    required this.gender,
    required this.weight,
    required this.height,
    required this.mainInjuryType,
    required this.specificInjury,
    required this.painLevel,
    required this.trainingTime,
  });

  // Добавлены параметры в функцию toMap()
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'weight': weight,
      'height': height,
      'mainInjuryType':
          mainInjuryType, // Исправлено: injuryType -> mainInjuryType
      'specificInjury': specificInjury, // Добавлено
      'painLevel': painLevel,
      'trainingTime': trainingTime,
    };
  }

  RecoveryData copy() {
    return RecoveryData(
      name: name,
      gender: gender,
      weight: weight,
      height: height,
      mainInjuryType: mainInjuryType,
      specificInjury: specificInjury,
      painLevel: painLevel,
      trainingTime: trainingTime,
    );
  }

  // Добавлены параметры в функцию fromMap()
  factory RecoveryData.fromMap(Map<String, dynamic> map) {
    return RecoveryData(
      id: map['id'],
      name: map['name'],
      gender: map['gender'],
      weight: map['weight'],
      height: map['height'],
      mainInjuryType:
          map['mainInjuryType'], // Исправлено: injuryType -> mainInjuryType
      specificInjury: map['specificInjury'], // Добавлено
      painLevel: map['painLevel'],
      trainingTime: map['trainingTime'],
    );
  }
}

class EditableRecoveryData {
  int? id;
  String name;
  String gender;
  double weight;
  double height;
  String mainInjuryType;
  String specificInjury;
  int painLevel;
  String trainingTime;

  EditableRecoveryData({
    this.id,
    required this.name,
    required this.gender,
    required this.weight,
    required this.height,
    required this.mainInjuryType,
    required this.specificInjury,
    required this.painLevel,
    required this.trainingTime,
  });

  factory EditableRecoveryData.fromRecoveryData(RecoveryData data) {
    return EditableRecoveryData(
      id: data.id,
      name: data.name,
      gender: data.gender,
      weight: data.weight,
      height: data.height,
      mainInjuryType: data.mainInjuryType,
      specificInjury: data.specificInjury,
      painLevel: data.painLevel,
      trainingTime: data.trainingTime,
    );
  }

  RecoveryData toRecoveryData() {
    return RecoveryData(
      id: id,
      name: name,
      gender: gender,
      weight: weight,
      height: height,
      mainInjuryType: mainInjuryType,
      specificInjury: specificInjury,
      painLevel: painLevel,
      trainingTime: trainingTime,
    );
  }
}

class Exercise {
  final String title;
  final String generalDescription;
  final Map<String, String> injurySpecificInfo;
  final List<String> suitableFor;
  final int maxPainLevel;
  final List<String> steps;
  final List<String> tags;
  final String? imageUrl;

  Exercise({
    required this.title,
    required this.generalDescription,
    this.injurySpecificInfo = const {},
    required this.suitableFor,
    required this.maxPainLevel,
    required this.steps,
    required this.tags,
    this.imageUrl,
  });
}

// Пример данных
final exampleExercises = [
  // Ортопедические травмы
  Exercise(
    title: 'Изометрическое напряжение мышц',
    generalDescription: 'Укрепление мышц без движения в суставе',
    injurySpecificInfo: {
      'Перелом конечностей':
          'Позволяет сохранить мышечный тонус без риска смещения отломков. '
          'Рекомендовано в период иммобилизации.',
      'Эндопротезирование сустава':
          'Подготовка мышц к нагрузкам после операции. '
          'Снижает риск послеоперационных осложнений.',
    },
    suitableFor: ['Перелом конечностей', 'Эндопротезирование сустава'],
    maxPainLevel: 3,
    steps: [
      'Напрягите мышцы конечности на 5-7 секунд',
      'Расслабьте на 10 секунд',
      'Повторите 10 раз для каждой группы мышц',
    ],
    tags: ['Без движения', 'Начальная стадия'],
    imageUrl:
        'https://alfagym.ru/wp-content/uploads/0/f/7/0f7116f26b4589c244b0dbea5a85868f.png',
  ),
  Exercise(
    title: 'Нейропластическая гимнастика',
    generalDescription: 'Восстановление нейромышечного контроля',
    injurySpecificInfo: {
      'Инсульт':
          'Стимулирует нейропластичность мозга через повторяющиеся движения. '
          'Помогает восстановить утраченные двигательные функции.',
      'Черепно-мозговая травма':
          'Улучшает межполушарное взаимодействие. '
          'Снижает спастичность мышц после длительной иммобилизации.',
    },
    suitableFor: ['Инсульт', 'Черепно-мозговая травма'],
    maxPainLevel: 2,
    steps: [
      'Перекрестные движения рук и ног',
      'Зеркальное рисование обеими руками',
      'Упражнения с балансировочной подушкой',
    ],
    tags: ['Неврология', 'Реабилитация'],
    imageUrl:
        'https://fs-thb02.getcourse.ru/fileservice/file/thumbnail/h/f7cf7029e510f783d145a7dfbf012b3a.jpg/s/f1200x/a/27502/sc/236',
  ),

  Exercise(
    title: 'Пассивная разработка сустава',
    generalDescription: 'Восстановление подвижности после иммобилизации',
    suitableFor: ['Разрыв связок', 'Эндопротезирование сустава'],
    maxPainLevel: 4,
    steps: [
      'С помощью инструктора или здоровой конечности',
      'Медленные сгибания/разгибания в суставе',
      'По 10 повторений в каждом направлении',
      '2 сеанса в день',
    ],
    tags: ['Восстановление амплитуды'],
    imageUrl: 'https://www.garant.ru/files/4/4/1198144/pict159-71833482.png',
  ),

  // Нейрохирургические проблемы
  Exercise(
    title: 'Дыхательная гимнастика',
    generalDescription:
        'Профилактика осложнений после операций на позвоночнике',
    suitableFor: ['Операция на позвоночнике', 'Инсульт'],
    maxPainLevel: 2,
    steps: [
      'Диафрагмальное дыхание лежа на спине',
      'Глубокий вдох через нос 4 секунды',
      'Медленный выдох через рот 6 секунд',
      '10 циклов 3 раза в день',
    ],
    tags: ['Дыхание', 'Профилактика'],
    imageUrl:
        'https://avatars.dzeninfra.ru/get-zen_doc/271828/pub_66878cc2e419264ab4d17cea_668791de1cbd0d0f23a4b89e/scale_1200',
  ),
  Exercise(
    title: 'Тренировка мелкой моторики',
    generalDescription: 'Восстановление после инсульта',
    suitableFor: ['Инсульт'],
    maxPainLevel: 3,
    steps: [
      'Собирание мелких предметов пальцами',
      'Рисование на песке',
      'Застегивание пуговиц',
      '15 минут 2 раза в день',
    ],
    tags: ['Моторика', 'Реабилитация'],
    imageUrl:
        'https://66000950.есимп.рф/upload/5775/images/big/de/01/de0131e9fe49e970c94b533a4371d334.jpeg',
  ),

  // Спортивные травмы
  Exercise(
    title: 'Растяжка ахиллова сухожилия',
    generalDescription: 'Восстановление после разрыва',
    suitableFor: ['Разрыв ахиллова сухожилия'],
    maxPainLevel: 5,
    steps: [
      'Стоя лицом к стене, руки на уровне груди',
      'Больную ногу отставить назад',
      'Медленно сгибать колени до чувства натяжения',
      'Удерживать 30 секунд, 5 подходов',
    ],
    tags: ['Растяжка', 'Постоперационный'],
    imageUrl:
        'https://zdorovko.info/wp-content/uploads/2016/01/rastyajka_ahillovogo_suhojyliya_vozle_stenki.jpg',
  ),
  Exercise(
    title: 'Стабилизация плечевого сустава',
    generalDescription: 'После вывиха плеча',
    suitableFor: ['Вывих плеча'],
    maxPainLevel: 4,
    steps: [
      'Использование эластичной ленты',
      'Наружная и внутренняя ротация плеча',
      '15 повторений в 3 подхода',
      'С контролем амплитуды',
    ],
    tags: ['Стабильность', 'Реабилитация'],
    imageUrl:
        'https://4youngmama.ru/wp-content/uploads/7/9/c/79cb777bbd1047ee0d583746b1edc5e6.jpeg',
  ),

  // Послеоперационная реабилитация
  Exercise(
    title: 'Восстановление мышц живота',
    generalDescription: 'После кесарева сечения',
    suitableFor: ['Кесарево сечение'],
    maxPainLevel: 3,
    steps: [
      'Лежа на спине с согнутыми коленями',
      'Медленное напряжение мышц тазового дна',
      'Удержание 5 секунд, 10 повторений',
      '3 раза в день',
    ],
    tags: ['Послеродовой период', 'Мышцы кора'],
    imageUrl:
        'https://mens-physic.ru/images/2021/04/img_16193987794077-1-1024x576.jpg',
  ),
  Exercise(
    title: 'Дыхание с сопротивлением',
    generalDescription: 'После абдоминальных операций',
    suitableFor: ['Аппендэктомия', 'Лапароскопические операции'],
    maxPainLevel: 2,
    steps: [
      'Использование дыхательного тренажера',
      'Медленный вдох через сопротивление',
      '10 повторений каждые 2 часа',
      'Контроль болевых ощущений',
    ],
    tags: ['Дыхание', 'Реабилитация'],
    imageUrl:
        'https://avatars.mds.yandex.net/i?id=f6ecad553610d5c32bea670c60233dc2-4231472-images-thumbs&n=13',
  ),

  // Хронические заболевания
  Exercise(
    title: 'Аквааэробика',
    generalDescription: 'Для пациентов с артритом',
    suitableFor: ['Артрит'],
    maxPainLevel: 3,
    steps: [
      'Упражнения в бассейне',
      'Медленные махи ногами',
      'Круговые движения суставами',
      '30 минут 3 раза в неделю',
    ],
    tags: ['Бассейн', 'Низкая нагрузка'],
    imageUrl:
        'https://sun9-18.userapi.com/impg/BV58GjcI4fD0jdhBF-8IPvJOGBCOHeTF1jpZDA/un1NfC95nn4.jpg?size=800x800&quality=95&sign=1576edc505725521e370b5641c3f0356&c_uniq_tag=mjAsPQMNyIJ5oIhm54UIyC5GJ8NWpkmdwWuqoDDFwUo&type=album',
  ),
  Exercise(
    title: 'Баланс-терапия',
    generalDescription: 'При рассеянном склерозе',
    suitableFor: ['Рассеянный склероз'],
    maxPainLevel: 2,
    steps: [
      'Стоя у опоры',
      'Перенос веса тела с ноги на ногу',
      'Удержание равновесия на одной ноге',
      '10 минут 2 раза в день',
    ],
    tags: ['Баланс', 'Координация'],
    imageUrl:
        'https://i.pinimg.com/originals/3b/1d/cb/3b1dcbdb6afa51ca53a25f0706a6983e.jpg',
  ),
];

// Добавим детализированные категории травм
final injuryCategories = {
  'Ортопедические': [
    'Перелом конечностей',
    'Эндопротезирование сустава',
    'Разрыв связок',
    'Другая ортопедическая травма',
  ],
  'Нейрохирургические': [
    'Инсульт',
    'Операция на позвоночнике',
    'Черепно-мозговая травма',
    'Другая нейрохирургическая проблема',
  ],
  'Спортивные травмы': [
    'Разрыв ахиллова сухожилия',
    'Вывих плеча',
    'Повреждение мениска',
    'Другая спортивная травма',
  ],
  'Послеоперационная реабилитация': [
    'Аппендэктомия',
    'Кесарево сечение',
    'Лапароскопические операции',
    'Другая послеоперационная реабилитация',
  ],
  'Хронические заболевания': [
    'Артрит',
    'Рассеянный склероз',
    'Остеохондроз',
    'Другое хроническое заболевание',
  ],
};
