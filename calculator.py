import math

# функции калькулятора
def add(x, y):
    return x + y

def subtract(x, y):
    return x - y

def multiply(x, y):
    return x * y

def divide(x, y):
    return x / y

def exponent(x, y):
    return x ** y

def square_root(x):
    return math.sqrt(x)

def sin(x):
    return math.sin(x)

def cos(x):
    return math.cos(x)

def tan(x):
    return math.tan(x)

def factorial(x):
    return math.factorial(x)

# вывод главного меню калькулятора
print("Выберите операцию.")
print("1. Сложение")
print("2. Вычитание")
print("3. Умножение")
print("4. Деление")
print("5. Возведение в степень")
print("6. Квадратный корень")
print("7. Синус")
print("8. Косинус")
print("9. Тангенс")
print("10. Факториал")

# запрос на выбор операции

choice = input("Введите номер операции (1-10): ")

# проверка на правильность выбора операции
while choice!=0:
    while choice not in ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10'):
     if choice=='0':
         quit()
     else:
         print("Некорректный ввод.")
         choice = input("Введите номер операции (1-10): ")
     # запрос на ввод чисел
    num1 = float(input("Введите первое число: "))
    num2 = float(input("Введите второе число: "))

     # выполнение выбранной операции
    if choice == '1':
         print(num1, "+", num2, "=", add(num1, num2))
    elif choice == '2':
         print(num1, "-", num2, "=", subtract(num1, num2))
    elif choice == '3':
         print(num1, "*", num2, "=", multiply(num1, num2))
    elif choice == '4':
         if num2 == 0:
              print("На ноль делить нельзя!")
         else:
            print(num1, "/", num2, "=", divide(num1, num2))
    elif choice == '5':
         print(num1, "^", num2, "=", exponent(num1, num2))
    elif choice == '6':
        if num1 < 0:
            print("Нельзя брать корень из отрицательного числа!")
        else:
            print("Квадратный корень из", num1, "=", square_root(num1))
    elif choice == '7':
            print("Синус", num1, "=", sin(num1))
    elif choice == '8':
        print("Косинус", num1, "=", cos(num1))
    elif choice == '9':
        print("Тангенс", num1, "=", tan(num1))
    elif choice == '10':
        num1=int(num1)
        print("Факториал", num1, "=", factorial(num1))
    choice = input("Введите номер операции (1-10): ")









