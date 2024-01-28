using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

enum Border
{
    MaxRight = 40,
    MaxBottom = 20
}

class SnakeGame
{
    private List<int[]> snake;
    private int[] food;
    private Direction direction;
    private bool gameOver;

    public SnakeGame()
    {
        snake = new List<int[]>();
        direction = Direction.Right;
        gameOver = false;

        snake.Add(new int[] { 5, 5 });
        snake.Add(new int[] { 4, 5 });
        snake.Add(new int[] { 3, 5 });

        SpawnFood();
    }

    private void SpawnFood()
    {
        Random random = new Random();
        int x = random.Next(1, (int)Border.MaxRight);
        int y = random.Next(1, (int)Border.MaxBottom);

        food = new int[] { x, y };
    }

    private void Draw()
    {
        Console.Clear();

        foreach (var segment in snake)
        {
            Console.SetCursorPosition(segment[0], segment[1]);
            Console.Write("■");
        }

        Console.SetCursorPosition(food[0], food[1]);
        Console.Write("&"); //выглядит аппетитно 
    }

    private void Move()
    {
        int[] head = snake.First().ToArray();

        switch (direction)
        {
            case Direction.Up:
                head[1]--;
                break;
            case Direction.Down:
                head[1]++;
                break;
            case Direction.Left:
                head[0]--;
                break;
            case Direction.Right:
                head[0]++;
                break;
        }

        if (head[0] <= 0  head[0] >= (int)Border.MaxRight  head[1] <= 0 || head[1] >= (int)Border.MaxBottom
            || snake.Any(segment => segment.SequenceEqual(head))) 
        {
            gameOver = true;
        }

        if (head.SequenceEqual(food))
        {
            snake.Insert(0, head);
            SpawnFood();
        }
        else
        {
            snake.Insert(0, head);
            snake.RemoveAt(snake.Count - 1);
        }
    }

    public void Start()
    {
        Console.CursorVisible = false;
        ConsoleKeyInfo keyInfo;

        while (!gameOver)
        {
            if (Console.KeyAvailable)
            {
                keyInfo = Console.ReadKey(true);

                switch (keyInfo.Key)
                {
                    case ConsoleKey.UpArrow:
                        direction = Direction.Up;
                        break;
                    case ConsoleKey.DownArrow:
                        direction = Direction.Down;
                        break;
                    case ConsoleKey.LeftArrow:
                        direction = Direction.Left;
                        break;
                    case ConsoleKey.RightArrow:
                        direction = Direction.Right;
                        break;
                }
            }

            Move();
            Draw();
            Thread.Sleep(100);
        }

        Console.Clear();
        Console.WriteLine("Game Over!");
    }
}

enum Direction
{
    Up,
    Down,
    Left,
    Right
}

class Program
{
    static void Main(string[] args)
    {
        SnakeGame snakeGame = new SnakeGame();
        snakeGame.Start();
    }
}