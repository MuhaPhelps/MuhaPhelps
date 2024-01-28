using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

class Program
{
    static void Main()
    {
        Console.WindowHeight = 16;
        Console.WindowWidth = 32;
        int screenWidth = Console.WindowWidth;
        int screenHeight = Console.WindowHeight;
        Random random = new Random();
        int headX = screenWidth / 2;
        int headY = screenHeight / 2;
        ConsoleColor headColor = ConsoleColor.Red;
        string direction = "RIGHT";
        int score = 0;
        int foodX = random.Next(1, screenWidth - 2);
        int foodY = random.Next(1, screenHeight - 2);
        bool foodVisible = true;
        List<int> tailX = new List<int>();
        List<int> tailY = new List<int>();
        double waitTime = 100;
        bool gameOver = false;

        while (!gameOver)
        {
            Console.Clear();
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("SNAKE GAME");
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("Score: " + score);
            Console.ForegroundColor = ConsoleColor.White;

            for (int i = 0; i < screenWidth; i++)
            {
                Console.SetCursorPosition(i, 0);
                Console.Write("■");
            }

            for (int i = 0; i < screenWidth; i++)
            {
                Console.SetCursorPosition(i, screenHeight - 1);
                Console.Write("■");
            }

            for (int i = 0; i < screenHeight; i++)
            {
                Console.SetCursorPosition(0, i);
                Console.Write("■");
            }

            for (int i = 0; i < screenHeight; i++)
            {
                Console.SetCursorPosition(screenWidth - 1, i);
                Console.Write("■");
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.SetCursorPosition(foodX, foodY);
            if (foodVisible)
                Console.Write("O");
            else
                Console.Write(" ");
            Console.ForegroundColor = ConsoleColor.White;
            Console.SetCursorPosition(headX, headY);
            Console.Write("■");

            for (int i = 0; i < tailX.Count(); i++)
            {
                Console.SetCursorPosition(tailX[i], tailY[i]);
                Console.Write("■");
                if (tailX[i] == headX && tailY[i] == headY)
                {
                    Console.Clear();
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("Game over!");
                    Console.ForegroundColor = ConsoleColor.White;
                    Console.WriteLine("Your score is: " + score);
                    Console.ReadLine();
                    gameOver = true;
                }
            }

            ConsoleKeyInfo keyInfo = Console.ReadKey();
            // Управление змейкой
            switch (keyInfo.Key)
            {
                case ConsoleKey.UpArrow:
                    direction = "UP";
                    break;
                case ConsoleKey.DownArrow:
                    direction = "DOWN";
                    break;
                case ConsoleKey.LeftArrow:
                    direction = "LEFT";
                    break;
                case ConsoleKey.RightArrow:
                    direction = "RIGHT";
                    break;
            }

            // Новая позиция головы
            switch (direction)
            {
                case "UP":
                    headY--;
                    break;
                case "DOWN":
                    headY++;
                    break;
                case "LEFT":
                    headX--;
                    break;
                case "RIGHT":
                    headX++;
                    break;
            }

            
            tailX.Insert(0, headX);
            tailY.Insert(0, headY);

            
            if (headX == foodX && headY == foodY)
            {
                score++;
                foodVisible = false;
                foodX = random.Next(1, screenWidth - 2);
                foodY = random.Next(1, screenHeight - 2);
            }
            else
            {
                foodVisible = true;
                Console.SetCursorPosition(tailX.Last(), tailY.Last());
                Console.Write(" ");
                tailX.RemoveAt(tailX.Count() - 1);
                tailY.RemoveAt(tailY.Count() - 1);
            }

            
            if (headX == 0 || headX == screenWidth - 1 || headY == 0 || headY == screenHeight - 1)
            {
                Console.Clear();
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Game over!");
                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("Your score is: " + score);
                Console.ReadLine();
                gameOver = true;
            }

            
            for (int i = 0; i < tailX.Count(); i++)
            {
                if (headX == tailX[i] && headY == tailY[i])
                {
                    Console.Clear();
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("Game over!");
                    Console.ForegroundColor = ConsoleColor.White;
                    Console.WriteLine("Your score is: " + score);
                    Console.ReadLine();
                    gameOver = true;
                }
            }

            Thread.Sleep(Convert.ToInt32(waitTime));
        }
    }
}