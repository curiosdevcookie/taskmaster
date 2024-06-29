# TaskMaster

## Specification and database design

The application is a simple task manager. A user can:

- create tasks and create sub-tasks,
- assign tasks to other users, and comment on them,
- upload pictures to a task,
- create tags and assign them to tasks.
- create locations and assign them to tasks
- participate in tasks

TaskMaster has the following entities:

### Users

The `users` table includes:

- `id`: UUID, PRIMARY KEY
- `first_name`: VARCHAR, NULL: FALSE
- `last_name`: VARCHAR, NULL: FALSE
- `nick_name`: CITEXT, UNIQUE
- `email`: CITEXT, UNIQUE, NULL: FALSE
- `roles`: ARRAY of VARCHAR, default `{"editor"}`, NULL: FALSE
- `hashed_password`: VARCHAR (redacted), NULL: FALSE
- `current_password`: VARCHAR (virtual field, redacted)
- `confirmed_at`: TIMESTAMP without time zone
- `last_login_at`: TIMESTAMP without time zone
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(email)`
- `UNIQUE(nick_name)`

Users can sign up and log in to the system. A user can have multiple roles. A user can have an avatar picture.

### Roles

The `roles` table includes:

- `id`: UUID, PRIMARY KEY
- `name`: VARCHAR
- `description`: TEXT
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(name)`

Users can have multiple roles. Roles can be assigned to multiple users.

### Avatars

The `avatars` table includes:

- `id`: UUID, PRIMARY KEY
- `path`: VARCHAR
- `user_id`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL

Users can upload many avatar files. An avatar file can be assigned to only one user.

### User Tokens

The `user_tokens` table includes:

- `id`: UUID, PRIMARY KEY
- `user_id`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `token`: BINARY, NULL: FALSE
- `context`: TEXT, NULL: FALSE
- `sent_to`: TEXT
- `inserted_at`: TIMESTAMP without time zone, NOT NULL

### Tasks

The `tasks` table includes:

- `id`: UUID, PRIMARY KEY
- `title`: VARCHAR, NULL: FALSE
- `description`: TEXT
- `due_date`: DATE
- `status`: ENUM('open', 'progressing', 'completed'), DEFAULT 'open', NULL: FALSE
- `duration`: INTEGER
- `completed_at`: TIMESTAMP without time zone
- `priority`: INTEGER
- `indoor`: BOOLEAN
- `created_by`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `parent_task_id`: UUID, FOREIGN KEY referencing `tasks(id)`
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(title)`

Users can add tasks to the system. A task can have a parent task. A task can have multiple sub-tasks. A task can have multiple tags. A task can have multiple locations. A task can have multiple pictures. A task can have multiple comments. A task can have multiple participations.
It also has a priority field that can be used to sort tasks and a duration field that can be used to estimate the time needed to complete the task.
It also has a status field that can be used to track the progress of the task. The status can be open, progressing, or completed. The completed_at field is used to store the date and time when the task was completed.
It also has a due_date field that can be used to set the deadline for the task.
It also has a created_by field that references the user who created the task.
It checks if it's an indoor or outdoor task.

### Task Participations

The `task_participations` table includes:

- `id`: UUID, PRIMARY KEY
- `user_id`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `task_id`: UUID, FOREIGN KEY referencing `tasks(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(user_id, task_id)`

A user can participate in a task. A user can be assigned to multiple tasks. A task can have multiple participants.

### Task locations

The `task_locations` table includes:

- `id`: UUID, PRIMARY KEY
- `task_id`: UUID, FOREIGN KEY referencing `tasks(id)`, NULL: FALSE
- `location_id`: UUID, FOREIGN KEY referencing `locations(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(task_id, location_id)`

A task can have multiple locations. A location can be assigned to multiple tasks.

### Locations

The `locations` table includes:

- `id`: UUID, PRIMARY KEY
- `name`: VARCHAR
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(name)`

Users can create locations that are visible and usable by all users in the system.

### Pictures

The `pictures` table includes:

- `id`: UUID, PRIMARY KEY
- `path`: VARCHAR
- `type`: ENUM('before', 'after')
- `user_id`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `task_id`: UUID, FOREIGN KEY referencing `tasks(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL

Users can upload pictures to a task. A picture can be of type before or after.

### Comments

The `comments` table includes:

- `id`: UUID, PRIMARY KEY
- `content`: TEXT, NULL: FALSE
- `created_by`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `task_id`: UUID, FOREIGN KEY referencing `tasks(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL

Users can comment on a task. A task can have multiple comments.

### Tags

The `tags` table includes:

- `id`: UUID, PRIMARY KEY
- `name`: VARCHAR, NULL: FALSE
- `description`: TEXT
- `colour`: VARCHAR(7), NULL: FALSE
- `created_by`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(name)`

Users can create tags that are visible and usable by all users in the system.

### Task Tags

The `task_tags` table includes:

- `id`: UUID, PRIMARY KEY
- `tag_id`: UUID, FOREIGN KEY referencing `tags(id)`, NULL: FALSE
- `task_id`: UUID, FOREIGN KEY referencing `tasks(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(tag_id, task_id)`

A task can have multiple tags. A tag can be assigned to multiple tasks.

### Task Assignments

The `task_assignments` table includes:

- `id`: UUID, PRIMARY KEY
- `user_id`: UUID, FOREIGN KEY referencing `users(id)`, NULL: FALSE
- `task_id`: UUID, FOREIGN KEY referencing `tasks(id)`, NULL: FALSE
- `inserted_at`: TIMESTAMP without time zone, NOT NULL
- `updated_at`: TIMESTAMP without time zone, NOT NULL
- `UNIQUE(user_id, task_id)`

A user can be assigned to a task. A task can have multiple assignments. A user can be assigned to multiple tasks.
