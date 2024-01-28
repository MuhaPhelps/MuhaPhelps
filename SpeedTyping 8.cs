using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Threading;
using Newtonsoft.Json;

class TypingTest
{
    static string[] words = { "пыццы", "шарп", "плюсы", "хычапури", "алег", "поставте", "пожалуйста", "не", "2", "прошуууу" };
    static Random random = new Random();
    static Stopwatch stopwatch = new Stopwatch();
    static int wordCount = 0;
    static int correctCount = 0;
    static bool testInProgress = true;
    static List<TestResult> results = new List<TestResult>(); 
    static void Main()
    {
        Console.WriteLine("Добро пожаловать в тест на скорость печатания!");
        Console.Write("Введите ваше имя: ");
        string userName = Console.ReadLine();

        Console.WriteLine("Введите 'готов' и нажмите Enter, чтобы начать.");

        string readiness = Console.ReadLine();
        if (readiness.ToLower() == "готов")
        {
            Console.Clear();

            Thread timerThread = new Thread(Timer);
            timerThread.Start();

            RunTypingTest();

            timerThread.Join();

            SaveResultsToJson(userName, results);
        }
        else
        {
            Console.WriteLine("Выход из программы. Нажмите любую клавишу...");
            Console.ReadKey();
        }
    }

    static void RunTypingTest()
    {
        stopwatch.Start();

        while (wordCount < words.Length && testInProgress)
        {
            string currentWord = words[wordCount];
            Console.Write($"Введите слово '{currentWord}': ");
            string userInput = Console.ReadLine();

            if (userInput.ToLower() == currentWord)
            {
                Console.WriteLine("Правильно!");
                correctCount++;
            }
            else
            {
                Console.WriteLine("Неправильно. Попробуйте еще раз.");
            }

            wordCount++;
        }

        stopwatch.Stop();

        Console.WriteLine("\nТест завершен!");
        Console.WriteLine($"Количество правильных слов: {correctCount}/{words.Length}");
        Console.WriteLine($"Время, затраченное на тест: {stopwatch.Elapsed.TotalSeconds} секунд");
    }

    static void Timer()
    {
        int testDurationSeconds = 60;

        for (int i = 0; i < testDurationSeconds; i++)
        {
            Thread.Sleep(1000);
        }

        testInProgress = false;
    }

    static void SaveResultsToJson(string userName, List<TestResult> existingResults)
    {
        TestResult result = new TestResult
        {
            UserName = userName,
            CorrectCount = correctCount,
            TotalWords = words.Length,
            TestDurationSeconds = stopwatch.Elapsed.TotalSeconds,
            WordsPerSecond = (correctCount / stopwatch.Elapsed.TotalSeconds)
        };

        existingResults.Add(result);

        string json = JsonConvert.SerializeObject(existingResults, Formatting.Indented);
        File.WriteAllText("test_results.json", json);

        Console.WriteLine("Результаты сохранены в файле 'test_results.json'");
        Console.WriteLine($"Скорость печати в словах в секунду: {result.WordsPerSecond:F2} слов/сек");
        Console.WriteLine("Нажмите любую клавишу, чтобы выйти...");
        Console.ReadKey();
    }
}

class TestResult
{
    public string UserName { get; set; }
    public int CorrectCount { get; set; }
    public int TotalWords { get; set; }
    public double TestDurationSeconds { get; set; }
    public double WordsPerSecond { get; set; }
}
