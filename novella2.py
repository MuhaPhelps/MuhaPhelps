import json
import csv
import os
import random

SAVE_DIR = 'game_saves'
JSON_FILE = 'game_data.json'
CSV_FILE = 'game_data.csv'

class DungeonExplorer:
    def __init__(self):
        self.player = {'name': '', 'health': 100, 'inventory': []}
        self.current_location = 'Entrance'
        self.locations = {
            'Entrance': 'Ты стоишь у входа в подземелье.',
            'Hallway': 'Ты находишься в длинном коридоре.',
            'TreasureRoom': 'Ты в комнате с сокровищами!'
        }
        self.create_save_directory()

    def create_save_directory(self):
        if not os.path.exists(SAVE_DIR):
            os.makedirs(SAVE_DIR)

    def save_to_json(self):
        with open(os.path.join(SAVE_DIR, JSON_FILE), 'w') as json_file:
            json.dump({'player': self.player, 'location': self.current_location}, json_file, indent=4)

    def load_from_json(self):
        try:
            with open(os.path.join(SAVE_DIR, JSON_FILE), 'r') as json_file:
                data = json.load(json_file)
                self.player = data['player']
                self.current_location = data['location']
                print("Игра загружена из JSON файла.")
        except FileNotFoundError:
            print("Сохранение не найдено. Создана новая игра.")

    def save_to_csv(self):
        with open(os.path.join(SAVE_DIR, CSV_FILE), 'w', newline='') as csv_file:
            csv_writer = csv.writer(csv_file)
            csv_writer.writerow(['Player Name', 'Health', 'Inventory', 'Current Location'])
            csv_writer.writerow([self.player['name'], self.player['health'], self.player['inventory'], self.current_location])
            print("Данные сохранены в CSV файл.")

    def play(self):
        print("Добро пожаловать в Dungeon Explorer!")
        print("Ты находишься у входа в подземелье.")
        self.player['name'] = input("Введите имя персонажа: ")

        while True:
            print("\nТекущее местоположение:", self.current_location)
            print(self.locations[self.current_location])

            if self.current_location == 'TreasureRoom':
                print("Поздравляю! Ты нашел сокровища и завершил игру.")
                self.save_to_json()
                self.save_to_csv()
                break

            self.handle_random_event()

            print("Выберите следующий шаг:")
            print("1. Пойти вперед")
            print("2. Проверить инвентарь")
            print("3. Сохранить игру")
            print("4. Загрузить игру")
            print("5. Удалить сохранение")
            print("0. Выйти из игры")

            choice = input("Ваш выбор: ")

            if choice == "1":
                self.move_forward()
            elif choice == "2":
                self.check_inventory()
            elif choice == "3":
                self.save_to_json()
                print("Игра сохранена.")
            elif choice == "4":
                self.load_from_json()
            elif choice == "5":
                self.delete_saves()
            elif choice == "0":
                print("До свидания! Игра завершена.")
                break
            else:
                print("Некорректный ввод. Попробуйте еще раз.")

    def handle_random_event(self):
        event_chance = random.randint(1, 10)
        if event_chance <= 3:
            print("Внимание! Ты сталкиваешься с враждебным монстром!")
            self.handle_combat()

    def handle_combat(self):
        monster_health = random.randint(20, 50)
        print(f"Здоровье монстра: {monster_health}")

        while self.player['health'] > 0 and monster_health > 0:
            print("\nВыберите действие:")
            print("1. Атаковать монстра")
            print("2. Попытаться убежать")

            combat_choice = input("Ваш выбор: ")

            if combat_choice == "1":
                damage_player = random.randint(5, 15)
                damage_monster = random.randint(3, 10)

                print(f"Ты атакуешь монстра и наносишь {damage_player} урона.")
                print(f"Монстр контратакует и наносит {damage_monster} урона.")

                self.player['health'] -= damage_monster
                monster_health -= damage_player

                print(f"Твое здоровье: {self.player['health']}")
                print(f"Здоровье монстра: {monster_health}")
            elif combat_choice == "2":
                print("Ты попытался убежать, но монстр не отпускает.")
                damage_monster = random.randint(5, 15)
                print(f"Монстр атакует и наносит {damage_monster} урона.")
                self.player['health'] -= damage_monster
                print(f"Твое здоровье: {self.player['health']}")
            else:
                print("Некорректный ввод. Попробуйте еще раз.")

        if self.player['health'] <= 0:
            print("Ты был побежден монстром. Игра завершена.")
            exit()

        print("Ты победил монстра и продолжаешь свое приключение!")

    def move_forward(self):
        if self.current_location == 'Entrance':
            print("Ты двигаешься вперед и входишь в длинный коридор.")
            self.current_location = 'Hallway'
        elif self.current_location == 'Hallway':
            print("Ты идешь вперед и находишь комнату с сокровищами!")
            self.current_location = 'TreasureRoom'

    def check_inventory(self):
        print(f"Имя: {self.player['name']}")
        print(f"Здоровье: {self.player['health']}")
        print(f"Инвентарь: {', '.join(self.player['inventory'])}")

    def delete_saves(self):
        try:
            os.remove(os.path.join(SAVE_DIR, JSON_FILE))
            os.remove(os.path.join(SAVE_DIR, CSV_FILE))
            print("Сохранения удалены.")
        except FileNotFoundError:
            print("Сохранения не найдены.")

if __name__ == "__main__":
    dungeon_game = DungeonExplorer()
    dungeon_game.play()
