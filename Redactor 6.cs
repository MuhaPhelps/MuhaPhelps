using System;
using System.IO;
using Newtonsoft.Json;
using System.Xml.Serialization;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("Текстовый редактор с поддержкой JSON и XML");
        Console.WriteLine("Введите 'сохранить' для сохранения файла.");
        Console.WriteLine("Введите 'выйти' для выхода из программы.");
        Console.WriteLine("-----------------------------");

        Console.Write("Введите путь к файлу: ");
        string filePath = Console.ReadLine();

        string fileExtension = Path.GetExtension(filePath).ToLower();
        string[] lines = null;

        if (fileExtension == ".txt" && File.Exists(filePath))
        {
            lines = File.ReadAllLines(filePath);
            Console.WriteLine("Содержимое файла загружено.");
        }
        else if (fileExtension == ".json" && File.Exists(filePath))
        {
            string jsonContent = File.ReadAllText(filePath);
            lines = JsonConvert.DeserializeObject<string[]>(jsonContent);
            Console.WriteLine("JSON файл загружен.");
        }
        else if (fileExtension == ".xml" && File.Exists(filePath))
        {
            using (StreamReader reader = new StreamReader(filePath))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(string[]));
                lines = (string[])serializer.Deserialize(reader);
                Console.WriteLine("XML файл загружен.");
            }
        }
        else
        {
            lines = new string[0];
            Console.WriteLine("Файл не существует. Создан новый файл.");
        }

        while (true)
        {
            Console.WriteLine("-----------------------------");
            Console.WriteLine("Текущее содержимое файла:");
            for (int i = 0; i < lines.Length; i++)
            {
                Console.WriteLine($"{i + 1}. {lines[i]}");
            }
            Console.WriteLine("-----------------------------");

            Console.Write("Введите номер строки для редактирования (или 'сохранить'/'выйти'): ");
            string input = Console.ReadLine();

            if (input.ToLower() == "сохранить")
            {
                SaveFile(filePath, fileExtension, lines);
                Console.WriteLine("Изменения сохранены.");
            }
            else if (input.ToLower() == "выйти")
            {
                Console.WriteLine("Программа завершена.");
                break;
            }
            else if (int.TryParse(input, out int lineNumber) && lineNumber > 0 && lineNumber <= lines.Length)
            {
                Console.WriteLine($"Редактирование строки {lineNumber}. Текст: {lines[lineNumber - 1]}");
                Console.Write("Введите новый текст: ");
                string newText = Console.ReadLine();
                lines[lineNumber - 1] = newText;
            }
            else
            {
                Console.WriteLine("Недопустимый ввод. Попробуйте снова.");
            }
        }
    }

    static void SaveFile(string filePath, string fileExtension, string[] lines)
    {
        if (fileExtension == ".txt")
        {
            File.WriteAllLines(filePath, lines);
        }
        else if (fileExtension == ".json")
        {
            string jsonContent = JsonConvert.SerializeObject(lines, Formatting.Indented);
            File.WriteAllText(filePath, jsonContent);
        }
        else if (fileExtension == ".xml")
        {
            using (StreamWriter writer = new StreamWriter(filePath))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(string[]));
                serializer.Serialize(writer, lines);
            }
        }
    }
}