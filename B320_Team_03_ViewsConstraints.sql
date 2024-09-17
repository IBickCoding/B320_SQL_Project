/***********************************************************************************
	Script Name: B320_Team_03_ViewsConstraints.sql
	Development Team: Ian Bickford, Houston Henderson
	Script version: V1
	Last updated: 2024.04.24
	
	Purpose: 
	-Drop and create views applicable to B320_Team_03_CreateLoad.sql script.
        B320 Spring 2024 final project
	-Adds check constraints for AcademicTerm table to limit input values. 

	NOTE: Enrollments does not need a check constraint to limit grade values
		  as we have used a GradeInfo table that creates a GradeID, this limits the
		  values that can be entered and used.

	Instructions: 
	Execute this script in your course database to get updated views on data.
	
***********************************************************************************/

------------------- ADD Constraints --------------------------------------------------
--You only need to run this one time to add the contraint to the database. Comment out once these
--statements have been ran once. However, they need to be ran each time the database has been 
--dropped and created again.

ALTER TABLE AcademicTerm
ADD CONSTRAINT AK_TermLength 
CHECK 
(
	TermLength = 'Full' OR
	TermLength = 'Half 1st' OR
	TermLength = 'Half 2nd' OR
	TermLength = 'May'
)
GO

ALTER TABLE AcademicTerm
ADD CONSTRAINT AK_Season 
CHECK 
(
	Season = 'Summer' OR
	Season = 'Spring' OR
	Season = 'Fall'
)
GO

--------------------- DROP EXISTING VIEWS ------------------------------------------
DROP VIEW IF EXISTS [dbo].[vwInstructorPerformance]
DROP VIEW IF EXISTS [dbo].[vwInstructorStudentsTaught];
DROP VIEW IF EXISTS [dbo].[vwInstructorAverage];
DROP VIEW IF EXISTS [dbo].[vwInstructorInfo];
DROP VIEW IF EXISTS [dbo].[vwGPA]
GO
------------------- CREATE NEW VIEWS --------------------------------------------------
--View for GPA calculation and student classification.
CREATE VIEW vwGPA AS
SELECT Student.StudentID, StudentLName, StudentFName, 
		ROUND(SUM(GradePoints * MinimumCredit) / SUM(MinimumCredit), 2) AS GPA,
		SUM(MinimumCredit) AS CumulativeCredits,
		CASE WHEN SUM(MinimumCredit) <= 30 THEN '1st Year'
		WHEN SUM(MinimumCredit) > 30 AND SUM(MinimumCredit) <= 60  THEN '2nd Year'
		WHEN SUM(MinimumCredit) > 30 AND SUM(MinimumCredit) <= 60  THEN '2nd Year'
		WHEN SUM(MinimumCredit) > 60 AND SUM(MinimumCredit) <= 90  THEN '3rd Year'
		WHEN SUM(MinimumCredit) > 90 AND SUM(MinimumCredit) <= 120  THEN '4th Year'
		WHEN SUM(MinimumCredit) > 120 THEN 'Graduate'
		END AS Semester
FROM Student
INNER JOIN Enrollments
	ON Enrollments.StudentID = Student.StudentID
INNER JOIN CourseOfferings
	ON CourseOfferings.CourseOfferingID = Enrollments.CourseOfferingID
INNER JOIN CourseCatalog
	ON CourseCatalog.CourseCatalogID = CourseOfferings.CourseCatlogID
INNER JOIN GradeInfo
    ON Enrollments.GradeID = GradeInfo.GradeID
GROUP BY Student.StudentID, StudentLName, StudentFName
ORDER BY Student.StudentID ASC OFFSET 0 ROWS
GO

--View Part 1 of 3 for InstructorPerformance View
CREATE VIEW vwInstructorInfo AS
SELECT Instructors.InstructorID, InstructorFName, InstructorLName, COUNT(Instructors.InstructorID) AS CoursesTaught
FROM Instructors
INNER JOIN CourseOfferings
	ON CourseOfferings.Instructorid = Instructors.Instructorid
WHERE CourseOfferingID in
(
	SELECT CourseOfferingID
	FROM Enrollments
)
GROUP BY InstructorFName, InstructorLName, Instructors.InstructorID
ORDER BY InstructorID OFFSET 0 ROWS
GO

--View Part 2 of 3 for InstructorPerformance View
CREATE VIEW vwInstructorAverage AS
SELECT AVG(GradeID) AS AverageGrade, Instructors.InstructorID
FROM Enrollments
INNER JOIN CourseOfferings
	ON CourseOfferings.CourseOfferingID = Enrollments.CourseOfferingID
INNER JOIN Instructors
	ON Instructors.InstructorID = CourseOfferings.InstructorID
GROUP BY Enrollments.CourseOfferingID, Instructors.InstructorID
ORDER BY InstructorID OFFSET 0 ROWS
GO

--View Part 3 of 3 for InstructorPerformance View
CREATE VIEW vwInstructorStudentsTaught AS
SELECT COUNT(STUDENTID) AS StudentsTaught, Instructors.InstructorID
FROM Enrollments
INNER JOIN CourseOfferings
	ON CourseOfferings.CourseOfferingID = Enrollments.CourseOfferingID
INNER JOIN Instructors
	ON Instructors.InstructorID = CourseOfferings.InstructorID
GROUP BY Instructors.InstructorID
ORDER BY InstructorID OFFSET 0 ROWS
GO

--InstructorPerformance view, shows instructor information, how many students that instructor has taught, and the average grade that instructor gives in their classes.
CREATE VIEW vwInstructorPerformance AS
SELECT vwInstructorInfo.InstructorID, InstructorFName, InstructorLName, CoursesTaught, StudentsTaught,
CASE 
	WHEN AVG(averageGrade) = 1 THEN 'A'
	WHEN AVG(averageGrade) = 2 THEN 'B+'
	WHEN AVG(averageGrade) = 3 THEN 'B'
	WHEN AVG(averageGrade) = 4 THEN 'C+'
	WHEN AVG(averageGrade) = 5 THEN 'C'
	WHEN AVG(averageGrade) = 6 THEN 'D+'
	WHEN AVG(averageGrade) = 7 THEN 'D'
	WHEN AVG(averageGrade) < 7 THEN 'F'
	END AS InstructorAverageGrade	
FROM vwInstructorInfo
LEFT JOIN vwInstructorAverage
	ON vwInstructorInfo.InstructorID = vwInstructorAverage.InstructorID 
LEFT JOIN vwInstructorStudentsTaught
	ON vwInstructorInfo.InstructorID = vwInstructorStudentsTaught.InstructorID
GROUP BY vwInstructorInfo.InstructorID, InstructorFName, InstructorLName, CoursesTaught, StudentsTaught
GO
