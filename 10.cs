using System;
using System.Collections.Generic;

namespace LibrarySystem
{
    public class Book
    {
        public string Title { get; set; }
        public string Author { get; set; }
        public int Year { get; set; }
        public bool IsAvailable { get; set; }

        public Book(string title, string author, int year)
        {
            Title = title;
            Author = author;
            Year = year;
            IsAvailable = true;
        }
    }

    public class Library
    {
        public List<Book> Books { get; set; }

        public Library()
        {
            Books = new List<Book>();
        }

        public void AddBook(string title, string author, int year)
        {
            Book newBook = new Book(title, author, year);
            Books.Add(newBook);
        }

        public void DisplayBooks()
        {
            Console.WriteLine("Books in the library:");
            foreach (var book in Books)
            {
                Console.WriteLine($"{book.Title} by {book.Author} ({book.Year}) - Available: {book.IsAvailable}");
            }
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            Library library = new Library();

            // Добавим несколько книг
            library.AddBook("Harry Potter and the Sorcerer's Stone", "J.K. Rowling", 1997);
            library.AddBook("To Kill a Mockingbird", "Harper Lee", 1960);
            library.AddBook("The Great Gatsby", "F. Scott Fitzgerald", 1925);

            // Выведем информацию о книгах
            library.DisplayBooks();

            // Добавим новую книгу через консольный ввод
            Console.WriteLine("\nEnter information for a new book:");
            Console.Write("Title: ");
            string newTitle = Console.ReadLine();

            Console.Write("Author: ");
            string newAuthor = Console.ReadLine();

            Console.Write("Year: ");
            int newYear;
            while (!int.TryParse(Console.ReadLine(), out newYear))
            {
                Console.WriteLine("Invalid input. Please enter a valid year.");
            }

            library.AddBook(newTitle, newAuthor, newYear);

            // Выведем обновленную информацию о книгах
            library.DisplayBooks();
        }
    }
}