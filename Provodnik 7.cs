using System;
using System.IO;

public class EnhancedConsoleFileExplorer
{
    private static string currentDirectory;

    public static void Main()
    {
        Console.CursorVisible = false;

        DriveInfo[] drives = DriveInfo.GetDrives();
        int selectedDrive = 0;

        do
        {
            Console.Clear();
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("Выберите диск:");
            Console.ResetColor();

            for (int i = 0; i < drives.Length; i++)
            {
                if (i == selectedDrive)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.Write(">");
                }
                else
                {
                    Console.Write(" ");
                }
                Console.WriteLine(drives[i].Name);
                Console.ResetColor();
            }

            ConsoleKeyInfo driveKeyInfo = Console.ReadKey();

            if (driveKeyInfo.Key == ConsoleKey.UpArrow)
            {
                selectedDrive = (selectedDrive - 1 + drives.Length) % drives.Length;
            }
            else if (driveKeyInfo.Key == ConsoleKey.DownArrow)
            {
                selectedDrive = (selectedDrive + 1) % drives.Length;
            }
            else if (driveKeyInfo.Key == ConsoleKey.Enter)
            {
                currentDirectory = drives[selectedDrive].RootDirectory.FullName;
                break;
            }
        } while (true);

        RunFileExplorer();
    }

    private static void RunFileExplorer()
    {
        ConsoleKeyInfo keyInfo;
        int selectedOption = 0;

        do
        {
            Console.Clear();
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("Консольный Проводник");
            Console.ResetColor();
            DisplayCurrentDirectory();

            string[] options = { "Просмотр содержимого каталога", "Перейти в подкаталог", "Создать файл", "Создать директорию", "Удалить файл", "Удалить директорию", "Вернуться в родительский каталог", "Выход" };

            for (int i = 0; i < options.Length; i++)
            {
                if (i == selectedOption)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.Write(">");
                }
                else
                {
                    Console.Write(" ");
                }
                Console.WriteLine(options[i]);
                Console.ResetColor();
            }

            keyInfo = Console.ReadKey();

            if (keyInfo.Key == ConsoleKey.UpArrow)
            {
                selectedOption = (selectedOption - 1 + options.Length) % options.Length;
            }
            else if (keyInfo.Key == ConsoleKey.DownArrow)
            {
                selectedOption = (selectedOption + 1) % options.Length;
            }
            else if (keyInfo.Key == ConsoleKey.Enter)
            {
                switch (selectedOption)
                {
                    case 0:
                        DisplayDirectoryContents(currentDirectory);
                        break;
                    case 1:
                        ChangeToSubdirectory();
                        break;
                    case 2:
                        CreateFile();
                        break;
                    case 3:
                        CreateDirectory();
                        break;
                    case 4:
                        DeleteFile();
                        break;
                    case 5:
                        DeleteDirectory();
                        break;
                    case 6:
                        NavigateToParentDirectory();
                        break;
                    case 7:
                        Environment.Exit(0);
                        break;
                }
            }
        } while (keyInfo.Key != ConsoleKey.Escape);
    }

    private static void DisplayCurrentDirectory()
    {
        Console.WriteLine($"Текущий каталог: {currentDirectory}");
    }

    private static void DisplayDirectoryContents(string directoryPath)
    {
        Console.Clear();
        Console.WriteLine($"Содержимое каталога '{directoryPath}':");
        string[] subdirectories = Directory.GetDirectories(directoryPath);
        string[] files = Directory.GetFiles(directoryPath);

        Console.WriteLine("Подкаталоги:");
        foreach (string subdirectory in subdirectories)
        {
            Console.WriteLine($"[П] {Path.GetFileName(subdirectory)}");
        }

        Console.WriteLine("Файлы:");
        foreach (string file in files)
        {
            Console.WriteLine($"[Ф] {Path.GetFileName(file)}");
        }

        Console.WriteLine("\nВведите имя файла для открытия (без квадратных скобок):");
        string selectedFile = Console.ReadLine();
        string selectedFilePath = Path.Combine(directoryPath, selectedFile);

        if (File.Exists(selectedFilePath))
        {
            OpenFile(selectedFilePath);
        }
        else
        {
            Console.WriteLine("Файл не найден.");
        }

        Console.WriteLine("\nНажмите любую клавишу для продолжения...");
        Console.ReadKey();
    }

    private static void OpenFile(string filePath)
    {
        try
        {
            Console.WriteLine($"Открывается файл: {filePath}");
            System.Diagnostics.Process.Start(filePath);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Не удалось открыть файл. Ошибка: {ex.Message}");
        }
    }

    private static void ChangeToSubdirectory()
    {
        Console.Clear();
        Console.Write("Введите имя подкаталога: ");
        string subdirectoryName = Console.ReadLine();
        string subdirectoryPath = Path.Combine(currentDirectory, subdirectoryName);

        if (Directory.Exists(subdirectoryPath))
        {
            currentDirectory = subdirectoryPath;
        }
        else
        {
            Console.WriteLine("Подкаталог не найден.");
        }
    }

    private static void CreateFile()
    {
        Console.Clear();
        Console.Write("Введите имя файла: ");
        string fileName = Console.ReadLine();
        string filePath = Path.Combine(currentDirectory, fileName);

        if (!File.Exists(filePath))
        {
            File.Create(filePath).Close();
            Console.WriteLine("Файл создан успешно.");
        }
        else
        {
            Console.WriteLine("Файл уже существует.");
        }
        Console.ReadKey();
    }

    private static void CreateDirectory()
    {
        Console.Clear();
        Console.Write("Введите имя директории: ");
        string dirName = Console.ReadLine();
        string dirPath = Path.Combine(currentDirectory, dirName);

        if (!Directory.Exists(dirPath))
        {
            Directory.CreateDirectory(dirPath);
            Console.WriteLine("Директория создана успешно.");
        }
        else
        {
            Console.WriteLine("Директория уже существует.");
        }
        Console.ReadKey();
    }

    private static void DeleteFile()
    {
        Console.Clear();
        Console.Write("Введите имя файла для удаления: ");
        string fileName = Console.ReadLine();
        string filePath = Path.Combine(currentDirectory, fileName);

        if (File.Exists(filePath))
        {
            File.Delete(filePath);
            Console.WriteLine("Файл удален успешно.");
        }
        else
        {
            Console.WriteLine("Файл не найден.");
        }
        Console.ReadKey();
    }

    private static void DeleteDirectory()
    {
        Console.Clear();
        Console.Write("Введите имя директории для удаления: ");
        string dirName = Console.ReadLine();
        string dirPath = Path.Combine(currentDirectory, dirName);


if (Directory.Exists(dirPath))
        {
            Directory.Delete(dirPath, true);
            Console.WriteLine("Директория удалена успешно.");
        }
        else
        {
            Console.WriteLine("Директория не найдена.");
        }
        Console.ReadKey();
    }

    private static void NavigateToParentDirectory()
    {
        string parentDirectory = Directory.GetParent(currentDirectory)?.FullName;
        if (parentDirectory != null)
        {
            currentDirectory = parentDirectory;
        }
        else
        {
            Console.WriteLine("Вы находитесь в корневом каталоге.");
        }
    }
}