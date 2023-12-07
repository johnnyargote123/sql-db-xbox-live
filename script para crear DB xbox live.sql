-- Crear la base de datos XboxLiveDB
CREATE DATABASE XboxLiveDB2;

-- Usar la base de datos XboxLiveDB
USE XboxLiveDB2;

-- Crear la tabla "users" para los usuarios
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  gamertag VARCHAR(255),
  registration_date TIMESTAMP NOT NULL
);

-- Crear la tabla "games" para los juegos
CREATE TABLE games (
  game_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  developer VARCHAR(255) NOT NULL,
  genre VARCHAR(255) NOT NULL,
  release_date TIMESTAMP NOT NULL
);

-- Crear la tabla "interactions" para las interacciones entre usuarios y juegos
CREATE TABLE interactions (
  interaction_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  game_id INT NOT NULL,
  interaction_type VARCHAR(255) NOT NULL,
  interaction_date TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (game_id) REFERENCES games(game_id)
);

-- Crear la tabla "events" para los eventos organizados por usuarios
CREATE TABLE events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  event_date TIMESTAMP NOT NULL,
  organizer_id INT NOT NULL,
  FOREIGN KEY (organizer_id) REFERENCES users(user_id)
);

-- Crear la tabla "friendships" para las amistades entre usuarios
CREATE TABLE friendships (
  friendship_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  friend_id INT NOT NULL,
  friendship_start_date TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (friend_id) REFERENCES users(user_id)
);

-- Crear la tabla "subscriptions" para las suscripciones de usuarios
CREATE TABLE subscriptions (
  subscription_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  subscription_type VARCHAR(100) NOT NULL,
  subscription_start_date TIMESTAMP NOT NULL,
  subscription_end_date TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);


-- Logs
CREATE TABLE interaction_logs (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  action_type VARCHAR(50) NOT NULL,
  game_id INT NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (game_id) REFERENCES games(game_id)
);

CREATE TABLE friendship_logs (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  action_type VARCHAR(50) NOT NULL,
  friend_id INT NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (friend_id) REFERENCES users(user_id)
);


-- vistas
CREATE VIEW UserSubscriptions AS
SELECT
  u.user_id,
  u.username,
  u.email,
  s.subscription_type,
  s.subscription_start_date,
  s.subscription_end_date
FROM users u
LEFT JOIN subscriptions s ON u.user_id = s.user_id;

CREATE VIEW GameGenres AS
SELECT
  g.game_id,
  g.name,
  g.developer,
  g.genre
FROM games g;

CREATE VIEW UserFriendships AS
SELECT
  f.friendship_id,
  u1.username AS user1_username,
  u2.username AS user2_username,
  f.friendship_start_date
FROM friendships f
INNER JOIN users u1 ON f.user_id = u1.user_id
INNER JOIN users u2 ON f.friend_id = u2.user_id;

CREATE VIEW EventOrganizers AS
SELECT
  e.event_id,
  e.name AS event_name,
  e.description AS event_description,
  e.event_date,
  u.username AS organizer_username
FROM events e
INNER JOIN users u ON e.organizer_id = u.user_id;



CREATE VIEW UserInteractions AS
SELECT
  i.interaction_id,
  u.username AS user_username,
  g.name AS game_name,
  i.interaction_type,
  i.interaction_date
FROM interactions i
INNER JOIN users u ON i.user_id = u.user_id
INNER JOIN games g ON i.game_id = g.game_id;



-- SELECT * FROM UserSubscriptions;
-- SELECT * FROM GameGenres;
-- SELECT * FROM UserFriendships;
-- SELECT * FROM EventOrganizers;
-- SELECT * FROM UserInteractions;



-- Funciones

DELIMITER //
CREATE FUNCTION GetGamesByGenreWithInteractions(genreName VARCHAR(255))
RETURNS TEXT
READS SQL DATA
BEGIN
  DECLARE gameList TEXT;

  SELECT GROUP_CONCAT(CONCAT(g.game_id, ':', g.name) SEPARATOR ', ')
  INTO gameList
  FROM games AS g
  INNER JOIN interactions AS i ON g.game_id = i.game_id
  WHERE g.genre = genreName;

  IF gameList IS NULL THEN
    SET gameList = 'No se encontraron juegos en este género.';
  END IF;

  RETURN gameList;
END;
//

DELIMITER ;




DELIMITER //


CREATE FUNCTION GetGameCountByGenre(genreName VARCHAR(255))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE gameCount INT;
  
  SET gameCount = (SELECT COUNT(*) FROM games WHERE genre = genreName);
 
  IF gameCount IS NULL THEN
    SET gameCount = 0;
  END IF;
  
  RETURN gameCount;
END;
//

DELIMITER ;



DELIMITER //
CREATE FUNCTION GetEventOrganizerName(eventID INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE organizerName VARCHAR(255);
  
  SELECT u.username INTO organizerName
  FROM events AS e
  INNER JOIN users AS u ON e.organizer_id = u.user_id
  WHERE e.event_id = eventID;
  
  RETURN organizerName;
END;
//
DELIMITER ;

-- SELECT GetEventOrganizerName(1);

-- Procedure

DELIMITER //
CREATE PROCEDURE SortTable(
    IN tableName VARCHAR(255),
    IN sortField VARCHAR(255),
    IN sortOrder VARCHAR(10)
)
BEGIN
    SET @sql = CONCAT('SELECT * FROM ', tableName, ' ORDER BY ', sortField, ' ', sortOrder, ';');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END;
//
DELIMITER ;
-- CALL SortTable('users', 'user_id', 'ASC');

DELIMITER //
CREATE PROCEDURE AddUser(
    IN newUsername VARCHAR(255),
    IN newEmail VARCHAR(255),
    IN newPassword VARCHAR(255),
    IN newGamertag VARCHAR(255)
)
BEGIN
    INSERT INTO users (username, email, password, gamertag, registration_date)
    VALUES (newUsername, newEmail, newPassword, newGamertag, NOW());
END;
//
DELIMITER ;

-- CALL AddUser('NuevoUsuario', 'nuevo@email.com', 'contraseña123', 'NuevoGamertag');
-- SELECT * FROM USERS;

DELIMITER //
CREATE PROCEDURE DeleteUserByUsername(
    IN usernameToDelete VARCHAR(255)
)
BEGIN
    -- Elimina el usuario por nombre de usuario
    DELETE FROM users WHERE username = usernameToDelete;
    
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario no se encontró';
    END IF;
END;
//
DELIMITER ;


-- CALL DeleteUserByUsername('NuevoUsuario');


-- Triggers 

DELIMITER //
CREATE TRIGGER before_interaction_insert
BEFORE INSERT ON interactions
FOR EACH ROW
BEGIN
  INSERT INTO interaction_logs (user_id, action_type, game_id, date, time)
  VALUES (NEW.user_id, NEW.interaction_type, NEW.game_id, CURDATE(), CURTIME());
END;
//
DELIMITER ;


DELIMITER //
CREATE TRIGGER after_interaction_delete
AFTER DELETE ON interactions
FOR EACH ROW
BEGIN
  INSERT INTO interaction_logs (user_id, action_type, game_id, date, time)
  VALUES (OLD.user_id, 'Eliminar', OLD.game_id, CURDATE(), CURTIME());
END;
//
DELIMITER ;

-- triggers FRIENDSHIP 
DELIMITER //
CREATE TRIGGER before_friendship_insert
BEFORE INSERT ON friendships
FOR EACH ROW
BEGIN
  INSERT INTO friendship_logs (user_id, action_type, friend_id, date, time)
  VALUES (NEW.user_id, 'Agregar amigo', NEW.friend_id, CURDATE(), CURTIME());
END;
//
DELIMITER ;


DELIMITER //
CREATE TRIGGER before_friendship_delete
BEFORE DELETE ON friendships
FOR EACH ROW
BEGIN
  INSERT INTO friendship_logs (user_id, action_type, friend_id, date, time)
  VALUES (OLD.user_id, 'Eliminar amigo', OLD.friend_id, CURDATE(), CURTIME());
END;
//
DELIMITER ;

-- EJEMPLO DE USO 

-- INSERT INTO friendships (user_id, friend_id, friendship_start_date) VALUES (21, 31, NOW());
-- SELECT * FROM friendships
-- SELECT * FROM friendship_logs
