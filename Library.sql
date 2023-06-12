CREATE DATABASE Library_Management_System;
CREATE TABLE Books (
BookID INT PRIMARY KEY,
Title VARCHAR(100),
Author VARCHAR(100),
PublicationYear INT,
Status VARCHAR(20)
);

CREATE TABLE Members (
MemberID INT PRIMARY KEY,
Name VARCHAR(100),
Address VARCHAR(100),
ContactNumber VARCHAR(20)
);

CREATE TABLE Loans (
LoanID INT PRIMARY KEY,
BookID INT,
MemberID INT,
LoanDate DATE,
ReturnDate DATE,
FOREIGN KEY (BookID) REFERENCES Books(BookID),
FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- Inserting data into the Books table
INSERT INTO Books (BookID, Title, Author, PublicationYear, Status)
VALUES (1, 'Book 1', 'Author 1', 2020, 'Available'),
       (2, 'Book 2', 'Author 2', 2018, 'Available'),
       (3, 'Book 3', 'Author 3', 2015, 'Available');

-- Inserting data into the Members table
INSERT INTO Members (MemberID, Name, Address, ContactNumber)
VALUES (1, 'Member 1', 'Address 1', '123'),
       (2, 'Member 2', 'Address 2', '987'),
       (3, 'Member 3', 'Address 3', '456');

-- Inserting data into the Loans table
INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
VALUES (1, 1, 1, '2023-05-01', '2023-06-01'),
       (2, 2, 1, '2023-05-05', '2023-06-05'),
       (3, 3, 2, '2023-05-10', '2023-06-10');


CREATE TRIGGER UpdateBookStatus
ON Loans
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS(SELECT * FROM inserted) 
    BEGIN
        UPDATE Books
        SET Status = 'Loaned'
        WHERE BookID IN (SELECT BookID FROM inserted);
    END;

    IF EXISTS(SELECT * FROM deleted) 
    BEGIN
        UPDATE Books
        SET Status = 'Available'
        WHERE BookID IN (SELECT BookID FROM deleted);
    END;
END;

WITH BorrowedBooks AS (
  SELECT MemberID, COUNT(*) AS BorrowedCount
  FROM Loans
  GROUP BY MemberID
  HAVING COUNT(*) >= 3
)
SELECT M.Name
FROM Members M
JOIN BorrowedBooks B ON M.MemberID = B.MemberID;

  CREATE FUNCTION CalculateOverdueDays(@LoanID INT)
RETURNS INT
AS
BEGIN
    DECLARE @DueDate DATE;
    DECLARE @ReturnDate DATE;
    DECLARE @OverdueDays INT;

    SELECT @DueDate = ReturnDate
    FROM Loans
    WHERE LoanID = @LoanID;

    SELECT @ReturnDate = GETDATE();

    SET @OverdueDays = DATEDIFF(DAY, @DueDate, @ReturnDate);

    IF @OverdueDays < 0
        SET @OverdueDays = 0;

    RETURN @OverdueDays;
END;

 CREATE VIEW OverdueLoansView AS
SELECT L.LoanID, B.Title AS BookTitle, M.Name AS MemberName, DATEDIFF(DAY, L.ReturnDate, GETDATE()) AS OverdueDays
FROM Loans L
JOIN Books B ON L.BookID = B.BookID
JOIN Members M ON L.MemberID = M.MemberID
WHERE L.ReturnDate < GETDATE();

CREATE TRIGGER PreventExcessiveBorrowing
ON Loans
AFTER INSERT
AS
BEGIN
    DECLARE @MemberID INT;
    DECLARE @BorrowedCount INT;

    SELECT @MemberID = MemberID
    FROM inserted;

    SELECT @BorrowedCount = COUNT(*)
    FROM Loans
    WHERE MemberID = @MemberID;

    IF @BorrowedCount >= 3
    BEGIN
        RAISERROR('Cannot borrow more than three books at a time.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;


-- Inserting additional data to test trigger functionality
INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
VALUES (6, 1, 3, '2023-05-15', '2023-06-15'); -- This should trigger the PreventExcessiveBorrowing trigger




-- Inserting data to test the OverdueLoansView
INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
VALUES (5, 1, 1, '2023-05-20', '2023-06-02'); -- This loan is overdue

-- Verify the OverdueLoansView
SELECT *
FROM OverdueLoansView;

-- Calling the CalculateOverdueDays function
DECLARE @OverdueDays INT;
SET @OverdueDays = dbo.CalculateOverdueDays(5); -- Assuming LoanID 5 is an overdue loan
SELECT @OverdueDays;




