import '../models/genre.dart';
import '../models/library_card.dart';
import '../models/publisher.dart';
import '../models/reader.dart';

const List<Genre> seedGenreEntities = [
  Genre(
    id: 1,
    name: 'Роман',
    description:
        'Крупная форма художественного повествования',
  ),
  Genre(
    id: 2,
    name: 'Фантастика',
    description:
        'Произведения с фантастическими допущениями',
  ),
  Genre(
    id: 3,
    name: 'Детектив',
    description:
        'Произведения о расследовании преступлений',
  ),
  Genre(
    id: 4,
    name: 'Антиутопия',
    description:
        'Изображение неблагоприятного общественного устройства',
  ),
  Genre(
    id: 5,
    name: 'Драма',
    description:
        'Произведения с выраженным конфликтом персонажей',
  ),
  Genre(
    id: 6,
    name: 'Приключения',
    description:
        'Произведения о путешествиях и приключениях',
  ),
];

const List<Publisher> seedPublisherEntities = [
  Publisher(
    id: 1,
    name: 'Эксмо',
    city: 'Москва',
    foundedYear: 1991,
  ),
  Publisher(
    id: 2,
    name: 'АСТ',
    city: 'Москва',
    foundedYear: 1990,
  ),
  Publisher(
    id: 3,
    name: 'Азбука',
    city: 'Санкт-Петербург',
    foundedYear: 1995,
  ),
  Publisher(
    id: 4,
    name: 'МИФ',
    city: 'Москва',
    foundedYear: 2005,
  ),
  Publisher(
    id: 5,
    name: 'Просвещение',
    city: 'Москва',
    foundedYear: 1930,
  ),
];

final List<Reader> seedReaders = [
  Reader(
    id: 1,
    fullName: 'Смирнов П. А.',
    email: 'smirnov@example.com',
    phone: '+7 900 000-00-01',
    card: LibraryCard(
      id: 1,
      number: 'RC-000001',
      issuedAt: DateTime(2026, 1, 15),
      expiresAt: DateTime(2027, 1, 15),
    ),
  ),
  Reader(
    id: 2,
    fullName: 'Иванова М. С.',
    email: 'ivanova@example.com',
    phone: '+7 900 000-00-02',
    card: LibraryCard(
      id: 2,
      number: 'RC-000002',
      issuedAt: DateTime(2026, 2, 1),
      expiresAt: DateTime(2027, 2, 1),
    ),
  ),
  Reader(
    id: 3,
    fullName: 'Петров А. В.',
    email: 'petrov@example.com',
    phone: '+7 900 000-00-03',
    card: LibraryCard(
      id: 3,
      number: 'RC-000003',
      issuedAt: DateTime(2026, 2, 12),
      expiresAt: DateTime(2027, 2, 12),
    ),
  ),
  Reader(
    id: 4,
    fullName: 'Соколова Е. И.',
    email: 'sokolova@example.com',
    phone: '+7 900 000-00-04',
    card: LibraryCard(
      id: 4,
      number: 'RC-000004',
      issuedAt: DateTime(2026, 3, 5),
      expiresAt: DateTime(2027, 3, 5),
    ),
  ),
  Reader(
    id: 5,
    fullName: 'Кузнецов Д. М.',
    email: 'kuznetsov@example.com',
    phone: '+7 900 000-00-05',
    card: LibraryCard(
      id: 5,
      number: 'RC-000005',
      issuedAt: DateTime(2026, 3, 20),
      expiresAt: DateTime(2027, 3, 20),
    ),
  ),
  Reader(
    id: 6,
    fullName: 'Морозова Н. А.',
    email: 'morozova@example.com',
    phone: '+7 900 000-00-06',
    card: LibraryCard(
      id: 6,
      number: 'RC-000006',
      issuedAt: DateTime(2026, 4, 8),
      expiresAt: DateTime(2027, 4, 8),
    ),
  ),
  Reader(
    id: 7,
    fullName: 'Волков И. О.',
    email: 'volkov@example.com',
    phone: '+7 900 000-00-07',
    card: LibraryCard(
      id: 7,
      number: 'RC-000007',
      issuedAt: DateTime(2026, 5, 14),
      expiresAt: DateTime(2027, 5, 14),
    ),
  ),
  Reader(
    id: 8,
    fullName: 'Фёдорова А. К.',
    email: 'fedorova@example.com',
    phone: '+7 900 000-00-08',
    card: LibraryCard(
      id: 8,
      number: 'RC-000008',
      issuedAt: DateTime(2026, 6, 10),
      expiresAt: DateTime(2027, 6, 10),
    ),
  ),
  Reader(
    id: 9,
    fullName: 'Орлов В. Р.',
    email: 'orlov@example.com',
    phone: '+7 900 000-00-09',
    card: LibraryCard(
      id: 9,
      number: 'RC-000009',
      issuedAt: DateTime(2026, 7, 2),
      expiresAt: DateTime(2027, 7, 2),
    ),
  ),
  Reader(
    id: 10,
    fullName: 'Лебедева Т. Н.',
    email: 'lebedeva@example.com',
    phone: '+7 900 000-00-10',
    card: LibraryCard(
      id: 10,
      number: 'RC-000010',
      issuedAt: DateTime(2026, 8, 1),
      expiresAt: DateTime(2027, 8, 1),
    ),
  ),
];