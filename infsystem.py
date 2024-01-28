import sqlite3

class ShopSystem:
    def __init__(self):
        self.conn = sqlite3.connect('shop_system.db')
        self.cursor = self.conn.cursor()
        self.create_tables()

    def create_tables(self):
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                price REAL
            )
        ''')

        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                role TEXT,
                full_name TEXT,
                username TEXT,
                password TEXT
            )
        ''')
        self.conn.commit()

    def add_product(self, name, price):
        self.cursor.execute('''
            INSERT INTO products (name, price) VALUES (?, ?)
        ''', (name, price))
        self.conn.commit()

    def view_products(self):
        self.cursor.execute('SELECT * FROM products')
        products = self.cursor.fetchall()

        if not products:
            print("Нет товаров в магазине.")
        else:
            for product in products:
                print(f"ID: {product[0]}, Название: {product[1]}, Цена: {product[2]}")

    def add_user(self, role, full_name, username, password):
        self.cursor.execute('''
            INSERT INTO users (role, full_name, username, password) VALUES (?, ?, ?, ?)
        ''', (role, full_name, username, password))
        self.conn.commit()

    def view_users(self):
        self.cursor.execute('SELECT * FROM users')
        users = self.cursor.fetchall()

        if not users:
            print("Нет пользователей в системе.")
        else:
            for user in users:
                print(f"ID: {user[0]}, Роль: {user[1]}, ФИО: {user[2]}, Логин: {user[3]}")

    def delete_user(self, user_id):
        self.cursor.execute('DELETE FROM users WHERE id=?', (user_id,))
        self.conn.commit()

    def modify_user(self, user_id, full_name, password):
        self.cursor.execute('''
            UPDATE users SET full_name=?, password=? WHERE id=?
        ''', (full_name, password, user_id))
        self.conn.commit()

    def run_console(self):
        while True:
            print("\nВыберите действие:")
            print("1. Просмотр товаров")
            print("2. Добавление товара")
            print("3. Просмотр пользователей")
            print("4. Добавление пользователя")
            print("5. Удаление пользователя")
            print("6. Модификация пользователя")
            print("0. Выход")

            choice = input("Введите номер действия: ")

            if choice == "1":
                self.view_products()
            elif choice == "2":
                name = input("Введите название товара: ")
                price = float(input("Введите цену товара: "))
                self.add_product(name, price)
            elif choice == "3":
                self.view_users()
            elif choice == "4":
                role = input("Введите роль пользователя (client/employee/admin): ")
                full_name = input("Введите ФИО пользователя: ")
                username = input("Введите логин пользователя: ")
                password = input("Введите пароль пользователя: ")
                self.add_user(role, full_name, username, password)
            elif choice == "5":
                user_id = int(input("Введите ID пользователя для удаления: "))
                self.delete_user(user_id)
            elif choice == "6":
                user_id = int(input("Введите ID пользователя для модификации: "))
                full_name = input("Введите новое ФИО пользователя: ")
                password = input("Введите новый пароль пользователя: ")
                self.modify_user(user_id, full_name, password)
            elif choice == "0":
                print("Программа завершена.")
                break
            else:
                print("Некорректный ввод. Попробуйте еще раз.")

if __name__ == "__main__":
    shop_system = ShopSystem()
    shop_system.run_console()
    shop_system.conn.close()
