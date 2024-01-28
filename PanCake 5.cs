using System;
using System.IO;
using System.Collections.Generic;

class Program
{
    static void Main(string[] args)
    {
        List<MenuItem> mainMenuItems = new List<MenuItem>
        {
            new MenuItem("Выбрать форму торта", 0),
            new MenuItem("Выбрать размер торта", 0),
            new MenuItem("Выбрать вкус торта", 0),
            new MenuItem("Выбрать количество тортов", 0),
            new MenuItem("Выбрать глазурь", 0),
            new MenuItem("Выбрать декор", 0),
            new MenuItem("Подтвердить заказ", 0),
            new MenuItem("Выход", 0)
        };

        Order currentOrder = new Order();
        int selectedItem = 0;
        bool isMainMenu = true;

        while (true)
        {
            Console.Clear();

            if (isMainMenu)
            {
                Console.WriteLine("Главное меню:");
            }
            else
            {
                Console.WriteLine("Дополнительное меню:");
            }

            for (int i = 0; i < mainMenuItems.Count; i++)
            {
                if (i == selectedItem)
                {
                    Console.Write("=> ");
                }
                else
                {
                    Console.Write("   ");
                }
                Console.WriteLine(mainMenuItems[i].Description);
            }

            ConsoleKeyInfo keyInfo = Console.ReadKey();

            if (keyInfo.Key == ConsoleKey.UpArrow)
            {
                selectedItem = (selectedItem - 1 + mainMenuItems.Count) % mainMenuItems.Count;
            }
            else if (keyInfo.Key == ConsoleKey.DownArrow)
            {
                selectedItem = (selectedItem + 1) % mainMenuItems.Count;
            }
            else if (keyInfo.Key == ConsoleKey.Enter)
            {
                if (isMainMenu)
                {
                    if (selectedItem == 6)
                    {
                        decimal totalPrice = currentOrder.TotalPrice();
                        currentOrder.SaveOrder(totalPrice);
                        currentOrder = new Order(); // Создаем новый заказ
                        Console.WriteLine("Заказ оформлен. Нажмите любую клавишу для продолжения.");
                        Console.ReadKey();
                    }
                    else if (selectedItem == 7)
                    {
                        Environment.Exit(0);
                    }
                    else
                    {
                        ShowSubMenu(currentOrder, mainMenuItems[selectedItem]);
                        isMainMenu = false;
                    }
                }
                else
                {
                    ProcessSubMenu(currentOrder, mainMenuItems[selectedItem]);
                }
            }
            else if (keyInfo.Key == ConsoleKey.Escape && !isMainMenu)
            {
                isMainMenu = true;
            }
        }
    }

    static void ShowSubMenu(Order currentOrder, MenuItem menuItem)
    {
        Console.Clear();
        Console.WriteLine($"Выбрано: {menuItem.Description}");
        Console.WriteLine("Дополнительное меню:");

        if (menuItem.Description == "Выбрать форму торта")
        {
            Console.WriteLine("1. Круглый");
            Console.WriteLine("2. Квадратный");
            Console.WriteLine("3. Сердце");
        }
        else if (menuItem.Description == "Выбрать размер торта")
        {
            Console.WriteLine("1. Маленький");
            Console.WriteLine("2. Средний");
            Console.WriteLine("3. Большой");
        }
        else if (menuItem.Description == "Выбрать вкус торта")
        {
            Console.WriteLine("1. Шоколадный");
            Console.WriteLine("2. Ванильный");
            Console.WriteLine("3. Фруктовый");
        }
        else if (menuItem.Description == "Выбрать количество тортов")
        {
            Console.WriteLine("Введите количество тортов:");
        }
        else if (menuItem.Description == "Выбрать глазурь")
        {
            Console.WriteLine("1. Шоколадная");
            Console.WriteLine("2. Ванильная");
            Console.WriteLine("3. Фруктовая");
        }
        else if (menuItem.Description == "Выбрать декор")
        {
            Console.WriteLine("1. Цветы");
            Console.WriteLine("2. Фигурки");
            Console.WriteLine("3. Буквы");
        }
    }

    static void ShowSubMenu(Order currentOrder, MenuItem menuItem)
    {
        Console.Clear();
        Console.WriteLine($"Выбрано: {menuItem.Description}");
        Console.WriteLine("Дополнительное меню:");

        if (menuItem.Description == "Выбрать форму торта")
        {
            Console.WriteLine("1. Круглый");
            Console.WriteLine("2. Квадратный");
            Console.WriteLine("3. Сердце");
        }
        else if (menuItem.Description == "Выбрать размер торта")
        {
            Console.WriteLine("1. Маленький");
            Console.WriteLine("2. Средний");
            Console.WriteLine("3. Большой");
        }
        else if (menuItem.Description == "Выбрать вкус торта")
        {
            Console.WriteLine("1. Шоколадный");
            Console.WriteLine("2. Ванильный");
            Console.WriteLine("3. Фруктовый");
        }
        else if (menuItem.Description == "Выбрать количество тортов")
        {
            Console.WriteLine("Введите количество тортов:");
        }
        else if (menuItem.Description == "Выбрать глазурь")
        {
            Console.WriteLine("1. Шоколадная");
            Console.WriteLine("2. Ванильная");
            Console.WriteLine("3. Фруктовая");
        }
        else if (menuItem.Description == "Выбрать декор")
        {
            Console.WriteLine("1. Цветы");
            Console.WriteLine("2. Фигурки");
            Console.WriteLine("3. Буквы");
        }
    }

    static void ProcessSubMenu(Order currentOrder, MenuItem menuItem)
    {
        if (menuItem.Description == "Выбрать форму торта")
        {
            Console.WriteLine("Выберите форму торта:");
            int formChoice = int.Parse(Console.ReadLine());
            if (formChoice == 1)
            {
                currentOrder.Form = "Круглый";
            }
            else if (formChoice == 2)
            {
                currentOrder.Form = "Квадратный";
            }
            else if (formChoice == 3)
            {
                currentOrder.Form = "Сердце";
            }
        }
        else if (menuItem.Description == "Выбрать размер торта")
        {
            Console.WriteLine("Выберите размер торта:");
            int sizeChoice = int.Parse(Console.ReadLine());
            if (sizeChoice == 1)
            {
                currentOrder.Size = "Маленький";
            }
            else if (sizeChoice == 2)
            {
                currentOrder.Size = "Средний";
            }
            else if (sizeChoice == 3)
            {
                currentOrder.Size = "Большой";
            }
        }
        else if (menuItem.Description == "Выбрать вкус торта")
        {
            Console.WriteLine("Выберите вкус торта:");
            int flavorChoice = int.Parse(Console.ReadLine());
            if (flavorChoice == 1)
            {
                currentOrder.Flavor = "Шоколадный";
            }
            else if (flavorChoice == 2)
            {
                currentOrder.Flavor = "Ванильный";
            }
            else if (flavorChoice == 3)
            {
                currentOrder.Flavor = "Фруктовый";
            }
        }
        else if (menuItem.Description == "Выбрать количество тортов")
        {
            Console.WriteLine("Введите количество тортов:");
            currentOrder.Quantity = int.Parse(Console.ReadLine());
        }
        else if (menuItem.Description == "Выбрать глазурь")
        {
            Console.WriteLine("Выберите глазурь:");
            int glazeChoice = int.Parse(Console.ReadLine());
            if (glazeChoice == 1)
            {
                currentOrder.Glaze = "Шоколадная";
            }
            else if (glazeChoice == 2)
            {
                currentOrder.Glaze = "Ванильная";
            }
            else if (glazeChoice == 3)
            {
                currentOrder.Glaze = "Фруктовая";
            }
        }
        else if (menuItem.Description == "Выбрать декор")
        {
            Console.WriteLine("Выберите декор:");
            int decorChoice = int.Parse(Console.ReadLine());
            if (decorChoice == 1)
            {
                currentOrder.Decor = "Цветы";
            }
            else if (decorChoice == 2)
            {
                currentOrder.Decor = "Фигурки";
            }
            else if (decorChoice == 3)
            {
                currentOrder.Decor = "Буквы";
            }
        }
    }

}

class MenuItem
{
    public string Description { get; set; }
    public decimal Price { get; set; }

    public MenuItem(string description, decimal price)
    {
        Description = description;
        Price = price;
    }
}

class Order
{
    public string Form { get; set; }
    public string Size { get; set; }
    public string Flavor { get; set; }
    public int Quantity { get; set; }
    public string Glaze { get; set; }
    public string Decor { get; set; }

    public decimal TotalPrice()
    {
        return 0;
    }

    public void SaveOrder(decimal totalPrice)
    {
        using (StreamWriter writer = File.AppendText("История заказов.txt"))
        {
            writer.WriteLine($"Заказ: {Quantity} тортов {Size} {Form} {Flavor} с глазурью {Glaze} и декором {Decor}. Сумма: {totalPrice} руб.");
        }
    }
}
