import pandas as pd

# Загружаем датасет
df = pd.read_csv('Terraria.csv')

# Выводим весь датасет и его описание
print("Датасет:")
print(df)

# Выводим размерность массива
print("\nРазмерность датасета:")
print(df.shape)

# Выводим наименование всех колонок и их описание
print("\nНазвания колонок и их описание:")
print(df.columns)

# Выводим все уникальные значения
print("\nУникальные значения в колонке 'CLASS':")
print(df['CLASS'].unique())

# Сортируем
print("\nДатасет, отсортированный по колонке DPS (SINGLE TARGET):")
print(df.sort_values(by='DPS (SINGLE TARGET)'))

# Удаляем столбец
df = df.drop(columns=['OBSERVATIONS'])

# Удаляем строки, где в колонке 'CLASS' указан цвет 'Mage'
df = df[df['CLASS'].str.lower() != 'Mage']

# Заменяем пустые значения в колонке 'Weight' на среднее значение
#df['Weight'].fillna(df['Weight'].mean(), inplace=True)

# Удаляем дубликаты
df = df.drop_duplicates()

# Анализ функцией info
print("\nАнализ с помощью функции info:")
print(df.info())

# Анализ функцией describe
print("\nАнализ с помощью функции describe:")
print(df.describe())

# Выборка данных с помощью loc
#print("\nВыборка данных с помощью loc:")
#print(df.loc[df[''] == '', ['', '']])

# Сохраняем новый датасет
df.to_csv('new_Terraria.csv', index=False)
