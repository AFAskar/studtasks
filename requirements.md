# Project Overview & Use Case

## Use Case: Academic Task Management for Student Groups

Students often work on group projects, study for shared classes, and have overlapping deadlines. Existing to-do apps are great for individuals but lack seamless, real-time synchronization for academic groups. "nadhm" is a web application that allows students to create shared course-specific to-do lists. For example, a group for "Computer Science 101" can have a shared list where all members can add, assign, complete, and discuss tasks related to that course's group project, homework, and exam deadlines.

## Core Value Proposition

It provides a single, synchronized, and course-centric view of tasks for a student group, reducing communication overhead and ensuring everyone is on the same page.

# Core Technical Requirements

Students must implement the following four pillars of the application:

## User Authentication

- Implement a secure user registration and login system.
- Each user must have a profile (at minimum: email, password, and display name).
- Must-Have Feature: Email Verification upon registration.
- Bonus Feature: "Forgot Password" functionality.
-

## B. Task Management (CRUD Operations)

- Create: Users can create new tasks with:
  - Title (required)
  - Description (optional)
  - Due Date (optional)
  - Priority Level (e.g., Low, Medium, High)
  - Assignment: Ability to assign a task to themselves or another member of the course/group.
- Read: View a list of tasks. Implement filtering (e.g., by status, assignee, priority) and sorting (e.g., by
  due date).
  Update: Mark a task as complete/incomplete, edit any task details.
  Delete: Remove a task from the list.

## C.Synchronization

- The Critical Feature: Real-time Synchronization. When any user in a course group adds, edits, or completes a task, the change must instantly and automatically appear on the screens of all other logged-in members of that group without requiring a page refresh. Data must be structured efficiently to reflect relationships: Users -> Courses -> Tasks.

## Frontend UI

The UI must include:

- A clean login/register page.
- A dashboard view showing an overview of the user's tasks across all courses.
- A dedicated view for each course/group, showing only its tasks.
- Forms for creating and editing tasks.
- A clear visual distinction between completed and pending tasks.

## Bonus Features (Optional)

- Push Notifications for assigned tasks or upcoming deadlines.
- File attachments to tasks (e.g., lecture notes, project drafts).
- Comments/Discussion thread on individual tasks.
- Data visualization of completed tasks per course.
- Drag-and-drop ordering of tasks.
- Offline capability (using service workers).
