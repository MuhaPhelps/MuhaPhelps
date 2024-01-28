using System;

class Calculator
{
    static void Main()
    {
        
        Console.Write("Введите первое число: ");
        double num1 = Convert.ToDouble(Console.ReadLine());

        Console.Write("Введите второе число: ");
        double num2 = Convert.ToDouble(Console.ReadLine());

        
        Console.Write("Выберите операцию (+, -, /, *, !, sqrt, ^): ");
        string operation = Console.ReadLine();

       
        switch (operation)
        {
            case "+":
                Console.WriteLine($"Результат: {num1} + {num2} = {num1 + num2}");
                break;

            case "-":
                Console.WriteLine($"Результат: {num1} - {num2} = {num1 - num2}");
                break;

            case "/":
                if (num2 != 0)
                {
                    Console.WriteLine($"Результат: {num1} / {num2} = {num1 / num2}");
                }
                else
                {
                    Console.WriteLine("Ошибка: деление на ноль");
                }
                break;

            case "*":
                Console.WriteLine($"Результат: {num1} * {num2} = {num1 * num2}");
                break;

            case "!":
                Console.WriteLine($"Факториал числа {num1} = {Factorial(num1)}");
                break;

            case "sqrt":
                Console.WriteLine($"Квадратный корень из числа {num1} = {Math.Sqrt(num1)}");
                break;

            case "^":
                Console.WriteLine($"Результат: {num1} в степени {num2} = {Math.Pow(num1, num2)}");
                break;

            default:
                Console.WriteLine("Ошибка: Неправильная операция");
                break;
        }
    }

   
    static double Factorial(double num)
    {
        if (num == 0)
        {
            return 1;
        }
        else
        {
            return num * Factorial(num - 1);
        }
    }
}