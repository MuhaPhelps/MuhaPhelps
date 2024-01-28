using System;
using System.Collections.Generic;

class Program
{
    static int currentOctave = 0;

    static int[][] octaves = new int[][]
    {
        new int[] { 261, 293, 329, 349, 392, 440, 493 }, 
        new int[] { 523, 587, 659, 698, 784, 880, 987 }, 
      
    };

    static void Main(string[] args)
    {
        Console.WriteLine("Привет мой маленький Моцарт!");
        Console.WriteLine("Используй клавиши A, S, D, F, G, H, J для игры");
        Console.WriteLine("Используй клавишу F1 для переключения октавы");
        Console.WriteLine("Используй клавишу Esc для выхода");

        while (true)
        {
            if (Console.KeyAvailable)
            {
                var key = Console.ReadKey(true).Key;

                if (key == ConsoleKey.Escape)
                    break;

                if (key == ConsoleKey.F1)
                {
                    SwitchOctave();
                    continue;
                }

                PlaySound(key);
            }
        }
    }

    static void PlaySound(ConsoleKey key)
    {
        int noteIndex = GetNoteIndex(key);

        if (noteIndex != -1)
        {
            int frequency = octaves[currentOctave][noteIndex];
            Console.Beep(frequency, 500); 
        }
    }

    static void SwitchOctave()
    {
        currentOctave++;

        if (currentOctave >= octaves.Length)
            currentOctave = 0;

        Console.WriteLine($"Переключена октава {currentOctave + 1}");
    }

    static int GetNoteIndex(ConsoleKey key)
    {
        Dictionary<ConsoleKey, int> keyToNoteIndex = new Dictionary<ConsoleKey, int>()
        {
            { ConsoleKey.A, 0 },
            { ConsoleKey.S, 1 },
            { ConsoleKey.D, 2 },
            { ConsoleKey.F, 3 },
            { ConsoleKey.G, 4 },
            { ConsoleKey.H, 5 },
            { ConsoleKey.J, 6 },
        };

        if (keyToNoteIndex.ContainsKey(key))
            return keyToNoteIndex[key];

        return -1;
    }
}