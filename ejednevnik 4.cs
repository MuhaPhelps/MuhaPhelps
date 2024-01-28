using System;
using System.Collections.Generic;

public class ConsoleDailyPlanner
{
    private static int selectedOption = 0;
    private static List<Note> notes = new List<Note>();

    public static void Main()
    {
        string[] menuOptions = { "Добавить заметку", "Просмотреть заметку", "Выход" };

        while (true)
        {
            Console.Clear();
            Console.WriteLine("Выберите действие:");

            for (int i = 0; i < menuOptions.Length; i++)
            {
                if (i == selectedOption)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("=> " + menuOptions[i]);
                    Console.ResetColor();
                }
                else
                {
                    Console.WriteLine("   " + menuOptions[i]);
                }
            }

            ConsoleKeyInfo keyInfo = Console.ReadKey();

            if (keyInfo.Key == ConsoleKey.UpArrow)
            {
                selectedOption = (selectedOption - 1 + menuOptions.Length) % menuOptions.Length;
            }
            else if (keyInfo.Key == ConsoleKey.DownArrow)
            {
                selectedOption = (selectedOption + 1) % menuOptions.Length;
            }
            else if (keyInfo.Key == ConsoleKey.Enter)
            {
                if (selectedOption == menuOptions.Length - 1)
                {
                    break;
                }
                else
                {
                    if (selectedOption == 0)
                    {
                        AddNote();
                    }
                    else if (selectedOption == 1)
                    {
                        DisplayNotes();
                    }

                    Console.WriteLine("Нажмите любую кнопку, чтобы продолжить...");
                    Console.ReadKey();
                }
            }
        }
    }

    private static void AddNote()
    {
        Console.Clear();
        Console.WriteLine("Введите название заметки:");
        string title = Console.ReadLine();

        Console.WriteLine("Введите описание заметки:");
        string description = Console.ReadLine();

        Console.WriteLine("Введите дату заметки (Формат: день/месяц/год):");
        string dateInput = Console.ReadLine();

        while (true)
        {
            string ashibka = Console.ReadLine();

            if (DateTime.TryParseExact(dateInput, "dd/MM/yyyy", null, System.Globalization.DateTimeStyles.None, out DateTime noteDate))
            {
                Note note = new Note { Title = title, Description = description, Date = noteDate };
                notes.Add(note);

                Console.WriteLine("Заметка успешно добавлена");
                break; 
            }
            else
            {
                Console.WriteLine("Неверный формат даты");
            }
        }
    }

    private static void DisplayNotes()
    {
        Console.Clear();
        Console.WriteLine("Список заметок:");

        foreach (var note in notes)
        {
            Console.WriteLine($"Название: {note.Title}");
            Console.WriteLine($"Описание: {note.Description}");
            Console.WriteLine($"Дата: {note.Date.ToShortDateString()}");
            Console.WriteLine();
        }
    }
}